package planner

import (
	"bufio"
	"fmt"
	"os"
	"regexp"
	"sort"
	"strings"
)

// ====== MODELI ======

type Column struct {
	Name       string
	Type       string // npr: uuid, text, integer, timestamp without time zone, user_status, ...
	NotNull    bool
	HasDefault bool
}

type Table struct {
	Name    string
	Columns []Column
}

type Schema struct {
	Enums  map[string][]string // enumName -> values
	Tables map[string]*Table   // tableName -> Table
}

// ForeignKey opisuje FK vezu: child.childColumn -> parent.parentColumn

// ParsePgDumpAll u jednom prolazu iz pg_dump fajla vadi:
// - schema (enums + tables + columns)
// - allTables (sve tabele viđene u CREATE/ALTER)
// - fks (FK-ovi iz inline REFERENCES i iz ALTER TABLE ... FOREIGN KEY ...)
// Radi sa multi-line ALTER TABLE iz pg_dump.
func ParsePgDumpAll(path string) (*Schema, []string, []ForeignKey, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, nil, nil, err
	}
	defer f.Close()

	schema := &Schema{
		Enums:  make(map[string][]string),
		Tables: make(map[string]*Table),
	}

	// ===== regexi =====
	reEnumStart := regexp.MustCompile(`(?i)^\s*CREATE\s+TYPE\s+(.+?)\s+AS\s+ENUM\s*\(\s*$`)
	reEnumVal := regexp.MustCompile(`^\s*'([^']+)'\s*,?\s*$`)

	reCreateTableStart := regexp.MustCompile(`(?i)^\s*CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(.+?)\s*\(\s*$`)

	// column line (uzimamo samo prvi ident, a ostatak "rest")
	reColLine := regexp.MustCompile(`^\s*("?[\w]+"?)\s+(.+)$`)

	// inline FK u CREATE TABLE liniji (rijetko, ali neka radi)
	reInlineRef := regexp.MustCompile(`(?i)^\s*("?[\w]+"?)\s+.*\bREFERENCES\b\s+(.+?)\s*\(\s*("?[\w]+"?)\s*\)`)

	// ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY (child_col) REFERENCES parent(parent_col)
	reAlterFK := regexp.MustCompile(`(?i)^\s*ALTER\s+TABLE\s+(?:ONLY\s+)?(.+?)\s+ADD\s+CONSTRAINT\s+.+?\bFOREIGN\s+KEY\s*\(\s*("?[\w]+"?)\s*\)\s+REFERENCES\s+(.+?)\s*\(\s*("?[\w]+"?)\s*\)`)

	// composite FK: FOREIGN KEY (a,b) REFERENCES parent(x,y)
	reAlterFKComposite := regexp.MustCompile(`(?i)^\s*ALTER\s+TABLE\s+(?:ONLY\s+)?(.+?)\s+ADD\s+CONSTRAINT\s+.+?\bFOREIGN\s+KEY\s*\(\s*([^)]+?)\s*\)\s+REFERENCES\s+(.+?)\s*\(\s*([^)]+?)\s*\)`)

	// ===== state =====
	tableSet := map[string]struct{}{}

	// nullable: table -> col -> isNullable
	nullable := map[string]map[string]bool{}

	flushTableSeen := func(t string) {
		t = normalizeIdent(t)
		if t == "" {
			return
		}
		tableSet[t] = struct{}{}
		if _, ok := nullable[t]; !ok {
			nullable[t] = map[string]bool{}
		}
	}

	// enum state
	inEnum := false
	var enumNameRaw string
	enumVals := make([]string, 0, 16)

	flushEnum := func() {
		name := normalizeTypeName(enumNameRaw)
		if name == "" {
			return
		}
		cp := make([]string, len(enumVals))
		copy(cp, enumVals)
		schema.Enums[name] = cp
	}

	// create table state
	inCreate := false
	var tableNameRaw string
	cols := make([]Column, 0, 64)

	flushTable := func() {
		tname := normalizeIdent(tableNameRaw)
		if tname == "" {
			return
		}
		// snimi tabelu u schema
		t := &Table{
			Name:    tname,
			Columns: make([]Column, 0, len(cols)),
		}
		t.Columns = append(t.Columns, cols...)
		schema.Tables[tname] = t
	}

	// statement buffer za ALTER TABLE (jer je multi-line)
	var stmtBuf strings.Builder

	// FK list
	fks := make([]ForeignKey, 0, 128)

	// helper: obradi završen statement (bez komentara)
	processStatement := func(stmt string) {
		stmt = strings.TrimSpace(stmt)
		if stmt == "" {
			return
		}

		stmtNorm := normalizeWhitespace(stmt)
		up := strings.ToUpper(stmtNorm)

		// uhvati ALTER TABLE <t> i bez FK (da se pojavi u allTables)
		if strings.HasPrefix(up, "ALTER TABLE") {
			parts := strings.Fields(stmtNorm)
			// ALTER TABLE [ONLY] <table> ...
			if len(parts) >= 3 {
				idx := 2
				if len(parts) >= 4 && strings.EqualFold(parts[2], "ONLY") {
					idx = 3
				}
				flushTableSeen(parts[idx])
			}
		}

		// single-column FK
		if m := reAlterFK.FindStringSubmatch(stmtNorm); m != nil {
			childTable := normalizeIdent(m[1])
			childCol := normalizeIdent(m[2])
			parentTable := normalizeIdent(m[3])
			parentCol := normalizeIdent(m[4])

			flushTableSeen(childTable)
			flushTableSeen(parentTable)

			isNullable := true
			if colsMap, ok := nullable[childTable]; ok {
				if v, ok2 := colsMap[childCol]; ok2 {
					isNullable = v
				}
			}

			fks = append(fks, ForeignKey{
				ChildTable:   childTable,
				ChildColumn:  childCol,
				ParentTable:  parentTable,
				ParentColumn: parentCol,
				IsNullable:   isNullable,
			})
			return
		}

		// composite FK -> razbij 1:1
		if m := reAlterFKComposite.FindStringSubmatch(stmtNorm); m != nil && strings.Contains(up, "FOREIGN KEY") {
			childTable := normalizeIdent(m[1])
			childColsRaw := m[2]
			parentTable := normalizeIdent(m[3])
			parentColsRaw := m[4]

			childCols := splitCols(childColsRaw)
			parentCols := splitCols(parentColsRaw)

			if len(childCols) == len(parentCols) && len(childCols) > 1 {
				flushTableSeen(childTable)
				flushTableSeen(parentTable)

				for i := 0; i < len(childCols); i++ {
					cc := normalizeIdent(childCols[i])
					pc := normalizeIdent(parentCols[i])

					isNullable := true
					if colsMap, ok := nullable[childTable]; ok {
						if v, ok2 := colsMap[cc]; ok2 {
							isNullable = v
						}
					}

					fks = append(fks, ForeignKey{
						ChildTable:   childTable,
						ChildColumn:  cc,
						ParentTable:  parentTable,
						ParentColumn: pc,
						IsNullable:   isNullable,
					})
				}
			}
		}
	}

	sc := bufio.NewScanner(f)

	for sc.Scan() {
		line := sc.Text()
		trim := strings.TrimSpace(line)

		// preskoči pg_dump meta i komentare
		if trim == "" {
			continue
		}
		if strings.HasPrefix(trim, "--") {
			continue
		}
		if strings.HasPrefix(trim, `\restrict`) || strings.HasPrefix(trim, `\unrestrict`) {
			continue
		}

		// ===== ENUM parsing (CREATE TYPE ... AS ENUM) =====
		if !inCreate && !inEnum {
			if m := reEnumStart.FindStringSubmatch(line); m != nil {
				inEnum = true
				enumNameRaw = m[1]
				enumVals = enumVals[:0]
				continue
			}
		}
		if inEnum {
			// kraj enum definicije
			if strings.HasPrefix(trim, ");") || trim == ");" || trim == ")" || strings.HasPrefix(trim, ")") {
				inEnum = false
				flushEnum()
				enumNameRaw = ""
				enumVals = enumVals[:0]
				continue
			}
			if m := reEnumVal.FindStringSubmatch(trim); m != nil {
				enumVals = append(enumVals, m[1])
			}
			continue
		}

		// ===== CREATE TABLE parsing =====
		if !inCreate {
			if m := reCreateTableStart.FindStringSubmatch(line); m != nil {
				inCreate = true
				tableNameRaw = m[1]
				cols = cols[:0]

				flushTableSeen(tableNameRaw)
				continue
			}
		} else {
			// kraj create table bloka
			if strings.HasPrefix(trim, ");") || trim == ");" || trim == ")" || strings.HasPrefix(trim, ")") {
				inCreate = false
				flushTable()
				tableNameRaw = ""
				cols = cols[:0]
				continue
			}

			up := strings.ToUpper(trim)
			// preskoči constraint linije unutar CREATE TABLE
			if strings.HasPrefix(up, "CONSTRAINT ") ||
				strings.HasPrefix(up, "PRIMARY KEY") ||
				strings.HasPrefix(up, "UNIQUE ") ||
				strings.HasPrefix(up, "CHECK ") ||
				strings.HasPrefix(up, "FOREIGN KEY") {
				continue
			}

			m := reColLine.FindStringSubmatch(line)
			if m == nil {
				continue
			}
			colName := normalizeIdent(m[1])
			rest := strings.TrimSpace(m[2])

			typ, notNull, hasDefault := parseColumnTypeAndFlags(rest)
			typ = normalizeTypeName(typ)

			cols = append(cols, Column{
				Name:       colName,
				Type:       typ,
				NotNull:    notNull,
				HasDefault: hasDefault,
			})

			// popuni nullable map (da FK IsNullable bude tačan)
			tname := normalizeIdent(tableNameRaw)
			if tname != "" {
				if _, ok := nullable[tname]; !ok {
					nullable[tname] = map[string]bool{}
				}
				nullable[tname][colName] = !notNull
			}

			// inline references u istoj liniji
			if im := reInlineRef.FindStringSubmatch(line); im != nil {
				childCol := normalizeIdent(im[1])
				parentTable := normalizeIdent(im[2])
				parentCol := normalizeIdent(im[3])
				childTable := normalizeIdent(tableNameRaw)

				flushTableSeen(childTable)
				flushTableSeen(parentTable)

				isNullable := true
				if colsMap, ok := nullable[childTable]; ok {
					if v, ok2 := colsMap[childCol]; ok2 {
						isNullable = v
					}
				}

				fks = append(fks, ForeignKey{
					ChildTable:   childTable,
					ChildColumn:  childCol,
					ParentTable:  parentTable,
					ParentColumn: parentCol,
					IsNullable:   isNullable,
				})
			}

			continue
		}

		// ===== Statement parsing (ALTER TABLE ... ; ) =====
		// Linija može imati više ';' -> split i flush svaki statement
		parts := strings.Split(line, ";")
		for i := 0; i < len(parts); i++ {
			part := parts[i]
			isLast := i == len(parts)-1

			stmtBuf.WriteString(part)
			stmtBuf.WriteString("\n")

			if !isLast {
				// statement završen na ';'
				processStatement(stmtBuf.String())
				stmtBuf.Reset()
			}
		}
	}

	if err := sc.Err(); err != nil {
		return nil, nil, nil, err
	}

	// flush ostatak ako ima bez ';'
	if rest := strings.TrimSpace(stmtBuf.String()); rest != "" {
		processStatement(rest)
	}

	// dedupe FK (pg_dump može imati duplikate)
	fks = dedupeFKs(fks)

	// allTables
	allTables := make([]string, 0, len(tableSet))
	for t := range tableSet {
		allTables = append(allTables, t)
	}
	sort.Strings(allTables)

	// sort fks stabilno
	sort.Slice(fks, func(i, j int) bool {
		if fks[i].ChildTable != fks[j].ChildTable {
			return fks[i].ChildTable < fks[j].ChildTable
		}
		if fks[i].ChildColumn != fks[j].ChildColumn {
			return fks[i].ChildColumn < fks[j].ChildColumn
		}
		if fks[i].ParentTable != fks[j].ParentTable {
			return fks[i].ParentTable < fks[j].ParentTable
		}
		return fks[i].ParentColumn < fks[j].ParentColumn
	})

	return schema, allTables, fks, nil
}

// ===== helperi =====

func parseColumnTypeAndFlags(rest string) (typ string, notNull bool, hasDefault bool) {
	upper := strings.ToUpper(rest)
	notNull = strings.Contains(upper, "NOT NULL")
	hasDefault = strings.Contains(upper, "DEFAULT")

	cutKeys := []string{" DEFAULT ", " NOT NULL", " CONSTRAINT ", " REFERENCES ", " CHECK ", " COLLATE "}
	cut := len(rest)
	for _, k := range cutKeys {
		if idx := strings.Index(upper, k); idx >= 0 && idx < cut {
			cut = idx
		}
	}
	typePart := strings.TrimSpace(rest[:cut])
	typePart = strings.TrimSuffix(typePart, ",")
	typePart = strings.TrimSpace(typePart)
	return typePart, notNull, hasDefault
}

func normalizeWhitespace(s string) string {
	fields := strings.Fields(s)
	return strings.Join(fields, " ")
}

func normalizeIdent(s string) string {
	s = strings.TrimSpace(s)
	s = strings.TrimSuffix(s, ",")
	s = strings.TrimSuffix(s, ";")
	s = strings.ReplaceAll(s, `"`, "")
	if strings.Contains(s, ".") {
		parts := strings.Split(s, ".")
		s = parts[len(parts)-1]
	}
	return strings.TrimSpace(s)
}

func normalizeTypeName(t string) string {
	t = strings.TrimSpace(t)
	t = strings.TrimSuffix(t, ",")
	t = strings.ReplaceAll(t, `"`, "")
	if strings.Contains(t, ".") {
		parts := strings.Split(t, ".")
		t = parts[len(parts)-1]
	}
	return normalizeWhitespace(t)
}

func splitCols(raw string) []string {
	raw = strings.ReplaceAll(raw, "\n", " ")
	raw = strings.ReplaceAll(raw, "\t", " ")
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		p = strings.Trim(p, `"`)
		if p != "" {
			out = append(out, p)
		}
	}
	return out
}

func dedupeFKs(in []ForeignKey) []ForeignKey {
	seen := map[string]struct{}{}
	out := make([]ForeignKey, 0, len(in))
	for _, fk := range in {
		key := fmt.Sprintf("%s.%s->%s.%s", fk.ChildTable, fk.ChildColumn, fk.ParentTable, fk.ParentColumn)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		out = append(out, fk)
	}
	return out
}

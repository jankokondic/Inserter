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
	Type       string
	NotNull    bool
	HasDefault bool
}

type Table struct {
	Name    string
	Columns []Column
}

type Schema struct {
	Enums  map[string][]string
	Tables map[string]*Table

	// table -> list of unique constraints; each constraint = list of column names
	// PRIMARY KEY takođe ulazi ovdje.
	UniqueConstraints map[string][][]string

	// table -> list of CHECK expressions (raw SQL inside CHECK(...))
	CheckConstraints map[string][]string
}

// ParsePgDumpAll: enums + tables/columns + fks + unique constraints + check constraints iz pg_dump fajla.
// KLJUČNO: preskače COPY ... FROM stdin; blokove (do linije \.)
func ParsePgDumpAll(path string) (*Schema, []string, []ForeignKey, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, nil, nil, err
	}
	defer f.Close()

	schema := &Schema{
		Enums:             make(map[string][]string),
		Tables:            make(map[string]*Table),
		UniqueConstraints: make(map[string][][]string),
		CheckConstraints:  make(map[string][]string),
	}

	// ===== regexi =====
	reEnumStart := regexp.MustCompile(`(?i)^\s*CREATE\s+TYPE\s+(.+?)\s+AS\s+ENUM\s*\(\s*$`)
	reEnumVal := regexp.MustCompile(`^\s*'([^']+)'\s*,?\s*$`)

	reCreateTableStart := regexp.MustCompile(`(?i)^\s*CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(.+?)\s*\(\s*$`)
	reColLine := regexp.MustCompile(`^\s*("?[\w]+"?)\s+(.+)$`)

	reInlineRef := regexp.MustCompile(`(?i)^\s*("?[\w]+"?)\s+.*\bREFERENCES\b\s+(.+?)\s*\(\s*("?[\w]+"?)\s*\)`)

	// FK
	reAlterFK := regexp.MustCompile(`(?i)^\s*ALTER\s+TABLE\s+(?:ONLY\s+)?(.+?)\s+ADD\s+CONSTRAINT\s+.+?\bFOREIGN\s+KEY\s*\(\s*("?[\w]+"?)\s*\)\s+REFERENCES\s+(.+?)\s*\(\s*("?[\w]+"?)\s*\)`)
	reAlterFKComposite := regexp.MustCompile(`(?i)^\s*ALTER\s+TABLE\s+(?:ONLY\s+)?(.+?)\s+ADD\s+CONSTRAINT\s+.+?\bFOREIGN\s+KEY\s*\(\s*([^)]+?)\s*\)\s+REFERENCES\s+(.+?)\s*\(\s*([^)]+?)\s*\)`)

	// PK / UNIQUE
	reAlterPK := regexp.MustCompile(`(?i)^\s*ALTER\s+TABLE\s+(?:ONLY\s+)?(.+?)\s+ADD\s+CONSTRAINT\s+.+?\bPRIMARY\s+KEY\s*\(\s*([^)]+?)\s*\)`)
	reAlterUnique := regexp.MustCompile(`(?i)^\s*ALTER\s+TABLE\s+(?:ONLY\s+)?(.+?)\s+ADD\s+CONSTRAINT\s+.+?\bUNIQUE\s*\(\s*([^)]+?)\s*\)`)

	// CHECK (ALTER TABLE ... ADD CONSTRAINT ... CHECK (...))
	reAlterCheckPrefix := regexp.MustCompile(`(?i)^\s*ALTER\s+TABLE\s+(?:ONLY\s+)?(.+?)\s+ADD\s+CONSTRAINT\s+.+?\bCHECK\b`)

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
		t := &Table{
			Name:    tname,
			Columns: make([]Column, 0, len(cols)),
		}
		t.Columns = append(t.Columns, cols...)
		schema.Tables[tname] = t
	}

	// CHECK parsing inside CREATE TABLE may span lines
	inCreateCheck := false
	createCheckDepth := 0
	var createCheckBuf strings.Builder

	addCheck := func(table string, expr string) {
		t := normalizeIdent(table)
		expr = strings.TrimSpace(expr)
		expr = strings.TrimSuffix(expr, ",")
		expr = strings.TrimSpace(expr)
		if t == "" || expr == "" {
			return
		}
		schema.CheckConstraints[t] = append(schema.CheckConstraints[t], expr)
	}

	// COPY block state
	inCopy := false

	// statement buffer for ';' terminated statements
	var stmtBuf strings.Builder

	// FK list
	fks := make([]ForeignKey, 0, 128)

	addUnique := func(table string, rawCols string) {
		t := normalizeIdent(table)
		if t == "" {
			return
		}
		colsU := splitCols(rawCols)
		if len(colsU) == 0 {
			return
		}
		for i := range colsU {
			colsU[i] = normalizeIdent(colsU[i])
		}
		schema.UniqueConstraints[t] = append(schema.UniqueConstraints[t], colsU)
	}

	processStatement := func(stmt string) {
		stmt = strings.TrimSpace(stmt)
		if stmt == "" {
			return
		}

		stmtNorm := normalizeWhitespace(stmt)
		up := strings.ToUpper(stmtNorm)

		// ALTER TABLE [ONLY] <table>
		if strings.HasPrefix(up, "ALTER TABLE") {
			parts := strings.Fields(stmtNorm)
			if len(parts) >= 3 {
				idx := 2
				if len(parts) >= 4 && strings.EqualFold(parts[2], "ONLY") {
					idx = 3
				}
				flushTableSeen(parts[idx])
			}
		}

		// PRIMARY KEY
		if m := reAlterPK.FindStringSubmatch(stmtNorm); m != nil {
			addUnique(m[1], m[2])
			flushTableSeen(m[1])
			return
		}

		// UNIQUE
		if m := reAlterUnique.FindStringSubmatch(stmtNorm); m != nil {
			addUnique(m[1], m[2])
			flushTableSeen(m[1])
			return
		}

		// CHECK
		if m := reAlterCheckPrefix.FindStringSubmatch(stmtNorm); m != nil && strings.Contains(up, " CHECK") {
			tbl := normalizeIdent(m[1])
			flushTableSeen(tbl)

			expr, ok := extractCheckExprFromStatement(stmtNorm)
			if ok {
				addCheck(tbl, expr)
			}
			return
		}

		// FK single
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

		// FK composite
		if m := reAlterFKComposite.FindStringSubmatch(stmtNorm); m != nil && strings.Contains(up, "FOREIGN KEY") {
			childTable := normalizeIdent(m[1])
			childCols := splitCols(m[2])
			parentTable := normalizeIdent(m[3])
			parentCols := splitCols(m[4])

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

		// COPY blok: ignoriši sve do \.
		if inCopy {
			if trim == `\.` {
				inCopy = false
			}
			continue
		}

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

		// START COPY blok
		if strings.HasPrefix(strings.ToUpper(trim), "COPY ") && strings.Contains(strings.ToUpper(trim), " FROM STDIN") {
			inCopy = true
			stmtBuf.Reset()
			continue
		}

		// ===== ENUM parsing =====
		if !inCreate && !inEnum {
			if m := reEnumStart.FindStringSubmatch(line); m != nil {
				inEnum = true
				enumNameRaw = m[1]
				enumVals = enumVals[:0]
				continue
			}
		}
		if inEnum {
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

				// reset CHECK state
				inCreateCheck = false
				createCheckDepth = 0
				createCheckBuf.Reset()

				continue
			}
		} else {
			// multi-line CHECK inside CREATE TABLE
			if inCreateCheck {
				createCheckBuf.WriteString("\n")
				createCheckBuf.WriteString(line)

				createCheckDepth += parenDelta(line)
				if createCheckDepth <= 0 {
					inCreateCheck = false
					expr, ok := extractCheckExprFromCreateBlock(createCheckBuf.String())
					if ok {
						addCheck(normalizeIdent(tableNameRaw), expr)
					}
					createCheckBuf.Reset()
					createCheckDepth = 0
				}
				continue
			}

			// kraj create table bloka
			if strings.HasPrefix(trim, ");") || trim == ");" || trim == ")" || strings.HasPrefix(trim, ")") {
				inCreate = false
				flushTable()
				tableNameRaw = ""
				cols = cols[:0]
				continue
			}

			up := strings.ToUpper(trim)

			// CHECK constraints inside CREATE TABLE
			if strings.Contains(up, "CHECK") && (strings.HasPrefix(up, "CONSTRAINT ") || strings.HasPrefix(up, "CHECK ")) {
				inCreateCheck = true
				createCheckBuf.Reset()
				createCheckBuf.WriteString(line)
				createCheckDepth = parenDelta(line)
				if createCheckDepth <= 0 {
					inCreateCheck = false
					expr, ok := extractCheckExprFromCreateBlock(createCheckBuf.String())
					if ok {
						addCheck(normalizeIdent(tableNameRaw), expr)
					}
					createCheckBuf.Reset()
					createCheckDepth = 0
				}
				continue
			}

			// preskoči constraint linije unutar CREATE TABLE koje nisu CHECK
			if strings.HasPrefix(up, "CONSTRAINT ") ||
				strings.HasPrefix(up, "PRIMARY KEY") ||
				strings.HasPrefix(up, "UNIQUE ") ||
				strings.HasPrefix(up, "FOREIGN KEY") {
				continue
			}

			// column line
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

			// nullable map
			tname := normalizeIdent(tableNameRaw)
			if tname != "" {
				if _, ok := nullable[tname]; !ok {
					nullable[tname] = map[string]bool{}
				}
				nullable[tname][colName] = !notNull
			}

			// inline references u istoj liniji
			if im := reInlineRef.FindStringSubmatch(line); im != nil {
				childTable := normalizeIdent(tableNameRaw)
				childCol := normalizeIdent(im[1])
				parentTable := normalizeIdent(im[2])
				parentCol := normalizeIdent(im[3])

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
		parts := strings.Split(line, ";")
		for i := 0; i < len(parts); i++ {
			part := parts[i]
			isLast := i == len(parts)-1

			stmtBuf.WriteString(part)
			stmtBuf.WriteString("\n")

			if !isLast {
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

	// dedupe FK
	fks = dedupeFKs(fks)

	// dedupe UNIQUE constraints (može pg_dump duplirati)
	for t, list := range schema.UniqueConstraints {
		schema.UniqueConstraints[t] = dedupeUniqueList(list)
	}

	// dedupe CHECK constraints
	for t, list := range schema.CheckConstraints {
		schema.CheckConstraints[t] = dedupeStringList(list)
	}

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

func dedupeStringList(in []string) []string {
	seen := map[string]struct{}{}
	out := make([]string, 0, len(in))
	for _, s := range in {
		k := normalizeWhitespace(strings.TrimSpace(s))
		if k == "" {
			continue
		}
		if _, ok := seen[k]; ok {
			continue
		}
		seen[k] = struct{}{}
		out = append(out, s)
	}
	return out
}

// dedupeUniqueList: input je [][]string (lista constraint-a; svaki constraint je lista kolona)
func dedupeUniqueList(in [][]string) [][]string {
	seen := map[string]struct{}{}
	out := make([][]string, 0, len(in))
	for _, cols := range in {
		key := strings.Join(cols, ",")
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		cp := make([]string, len(cols))
		copy(cp, cols)
		out = append(out, cp)
	}
	return out
}

// ---------- CHECK extraction helpers ----------

func extractCheckExprFromStatement(stmt string) (string, bool) {
	up := strings.ToUpper(stmt)
	idx := strings.Index(up, "CHECK")
	if idx < 0 {
		return "", false
	}
	rest := stmt[idx:]
	p := strings.Index(rest, "(")
	if p < 0 {
		return "", false
	}
	start := idx + p
	expr, ok := extractBalancedInsideParens(stmt, start)
	return expr, ok
}

func extractCheckExprFromCreateBlock(block string) (string, bool) {
	up := strings.ToUpper(block)
	idx := strings.Index(up, "CHECK")
	if idx < 0 {
		return "", false
	}
	rest := block[idx:]
	p := strings.Index(rest, "(")
	if p < 0 {
		return "", false
	}
	start := idx + p
	return extractBalancedInsideParens(block, start)
}

func extractBalancedInsideParens(s string, startIdx int) (string, bool) {
	if startIdx < 0 || startIdx >= len(s) || s[startIdx] != '(' {
		return "", false
	}

	depth := 0
	inStr := false

	for i := startIdx; i < len(s); i++ {
		ch := s[i]

		if inStr {
			if ch == '\'' {
				// doubled quotes '' inside string
				if i+1 < len(s) && s[i+1] == '\'' {
					i++
					continue
				}
				inStr = false
			}
			continue
		}

		if ch == '\'' {
			inStr = true
			continue
		}

		if ch == '(' {
			depth++
			continue
		}
		if ch == ')' {
			depth--
			if depth == 0 {
				inside := s[startIdx+1 : i]
				inside = strings.TrimSpace(inside)
				return inside, true
			}
		}
	}
	return "", false
}

func parenDelta(s string) int {
	d := 0
	inStr := false
	for i := 0; i < len(s); i++ {
		ch := s[i]
		if inStr {
			if ch == '\'' {
				if i+1 < len(s) && s[i+1] == '\'' {
					i++
					continue
				}
				inStr = false
			}
			continue
		}
		if ch == '\'' {
			inStr = true
			continue
		}
		if ch == '(' {
			d++
		} else if ch == ')' {
			d--
		}
	}
	return d
}

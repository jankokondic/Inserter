package planner

import (
	"bufio"
	"fmt"
	"os"
	"regexp"
	"sort"
	"strings"
)

// ParseSchemaSQL parsira pg_dump output i vraća sve tabele + FK odnose.
// Podržava 1-kolona FK i "dovoljno dobro" composite FK (razbije u više FK zapisa 1:1 po koloni).
func ParseSchemaSQL(path string) (allTables []string, fks []ForeignKey, err error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, nil, err
	}
	defer file.Close()

	// ===== Regexi za CREATE TABLE blok (linijski) =====

	// CREATE TABLE [IF NOT EXISTS] schema?.table (
	reCreateTableStart := regexp.MustCompile(`(?i)^\s*CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(.+?)\s*\(\s*$`)

	// column line:   col_name TYPE ... [NOT NULL] ...
	reColumnLine := regexp.MustCompile(`^\s*("?[\w]+"?)\s+`)

	// inline FK:   col UUID REFERENCES parent(parent_col) ...
	reInlineRef := regexp.MustCompile(`(?i)^\s*("?[\w]+"?)\s+.*\bREFERENCES\b\s+(.+?)\s*\(\s*("?[\w]+"?)\s*\)`)

	// ===== Regexi za ALTER TABLE ... ADD CONSTRAINT ... FK (na nivou statementa) =====

	reAlterFK := regexp.MustCompile(`(?i)^\s*ALTER\s+TABLE\s+(?:ONLY\s+)?(.+?)\s+ADD\s+CONSTRAINT\s+.+?\bFOREIGN\s+KEY\s*\(\s*("?[\w]+"?)\s*\)\s+REFERENCES\s+(.+?)\s*\(\s*("?[\w]+"?)\s*\)`)

	reAlterFKComposite := regexp.MustCompile(`(?i)^\s*ALTER\s+TABLE\s+(?:ONLY\s+)?(.+?)\s+ADD\s+CONSTRAINT\s+.+?\bFOREIGN\s+KEY\s*\(\s*([^)]+?)\s*\)\s+REFERENCES\s+(.+?)\s*\(\s*([^)]+?)\s*\)`)

	tableSet := map[string]struct{}{}

	// nullable map: table -> col -> isNullable
	nullable := map[string]map[string]bool{}

	flushTable := func(t string) {
		t = normalizeIdent(t)
		if t == "" {
			return
		}
		tableSet[t] = struct{}{}
		if _, ok := nullable[t]; !ok {
			nullable[t] = map[string]bool{}
		}
	}

	// ========= 1) PASS: CREATE TABLE blokovi (linijski) =========

	sc := bufio.NewScanner(file)
	var inCreate bool
	var currentTable string

	for sc.Scan() {
		line := sc.Text()

		if !inCreate {
			if m := reCreateTableStart.FindStringSubmatch(line); m != nil {
				inCreate = true
				currentTable = normalizeIdent(m[1])
				flushTable(currentTable)
				continue
			}
		}

		if inCreate {
			trim := strings.TrimSpace(line)

			// kraj CREATE TABLE
			if strings.HasPrefix(trim, ");") || trim == ");" || trim == ")" || strings.HasPrefix(trim, ")") {
				inCreate = false
				currentTable = ""
				continue
			}

			colMatch := reColumnLine.FindStringSubmatch(line)
			if colMatch != nil && currentTable != "" {
				col := normalizeIdent(colMatch[1])

				isNullable := !strings.Contains(strings.ToUpper(line), "NOT NULL")
				if _, ok := nullable[currentTable]; !ok {
					nullable[currentTable] = map[string]bool{}
				}
				nullable[currentTable][col] = isNullable

				// inline references (rijetko u pg_dump, ali neka radi)
				if m := reInlineRef.FindStringSubmatch(line); m != nil {
					childCol := normalizeIdent(m[1])
					parentTable := normalizeIdent(m[2])
					parentCol := normalizeIdent(m[3])

					flushTable(currentTable)
					flushTable(parentTable)

					n := true
					if cols, ok := nullable[currentTable]; ok {
						if v, ok2 := cols[childCol]; ok2 {
							n = v
						}
					}

					fks = append(fks, ForeignKey{
						ChildTable:   currentTable,
						ChildColumn:  childCol,
						ParentTable:  parentTable,
						ParentColumn: parentCol,
						IsNullable:   n,
					})
				}
			}
		}
	}

	if err := sc.Err(); err != nil {
		return nil, nil, err
	}

	// ========= 2) PASS: ALTER TABLE FK (po statementima) =========

	if _, err := file.Seek(0, 0); err != nil {
		return nil, nil, err
	}

	sc2 := bufio.NewScanner(file)

	var stmtBuf strings.Builder

	flushStmt := func(raw string) {
		s := strings.TrimSpace(raw)
		if s == "" {
			return
		}

		// normalizuj whitespace (multi-line -> single space)
		stmtNorm := normalizeWhitespace(s)

		// uhvati table iz bilo kojeg ALTER TABLE da se pojave kao čvorovi
		upper := strings.ToUpper(strings.TrimSpace(stmtNorm))
		if strings.HasPrefix(upper, "ALTER TABLE") {
			parts := strings.Fields(stmtNorm)
			if len(parts) >= 3 {
				idx := 2
				if len(parts) >= 4 && strings.EqualFold(parts[2], "ONLY") {
					idx = 3
				}
				flushTable(parts[idx])
			}
		}

		// single-column FK
		if m := reAlterFK.FindStringSubmatch(stmtNorm); m != nil {
			childTable := normalizeIdent(m[1])
			childCol := normalizeIdent(m[2])
			parentTable := normalizeIdent(m[3])
			parentCol := normalizeIdent(m[4])

			flushTable(childTable)
			flushTable(parentTable)

			n := true
			if cols, ok := nullable[childTable]; ok {
				if v, ok2 := cols[childCol]; ok2 {
					n = v
				}
			}

			fks = append(fks, ForeignKey{
				ChildTable:   childTable,
				ChildColumn:  childCol,
				ParentTable:  parentTable,
				ParentColumn: parentCol,
				IsNullable:   n,
			})
			return
		}

		// composite FK -> razbij u više FK 1:1
		if m := reAlterFKComposite.FindStringSubmatch(stmtNorm); m != nil && strings.Contains(upper, "FOREIGN KEY") {
			childTable := normalizeIdent(m[1])
			childColsRaw := m[2]
			parentTable := normalizeIdent(m[3])
			parentColsRaw := m[4]

			childCols := splitCols(childColsRaw)
			parentCols := splitCols(parentColsRaw)

			if len(childCols) == len(parentCols) && len(childCols) > 1 {
				flushTable(childTable)
				flushTable(parentTable)

				for i := 0; i < len(childCols); i++ {
					cc := normalizeIdent(childCols[i])
					pc := normalizeIdent(parentCols[i])

					n := true
					if cols, ok := nullable[childTable]; ok {
						if v, ok2 := cols[cc]; ok2 {
							n = v
						}
					}

					fks = append(fks, ForeignKey{
						ChildTable:   childTable,
						ChildColumn:  cc,
						ParentTable:  parentTable,
						ParentColumn: pc,
						IsNullable:   n,
					})
				}
			}
		}
	}

	for sc2.Scan() {
		line := sc2.Text()
		trim := strings.TrimSpace(line)

		// preskoči pg_dump komentare i meta-komande
		if trim == "" {
			continue
		}
		if strings.HasPrefix(trim, "--") {
			continue
		}
		if strings.HasPrefix(trim, `\restrict`) || strings.HasPrefix(trim, `\unrestrict`) {
			continue
		}

		// linija može imati više statementa, pa split po ';'
		// (pg_dump schema obično nema ';' u stringovima, pa je ovo OK)
		parts := strings.Split(line, ";")
		for i := 0; i < len(parts); i++ {
			part := parts[i]

			// zadnji dio nema završni ';' (osim ako je line završio sa ';' -> onda je zadnji dio "")
			isLast := i == len(parts)-1

			stmtBuf.WriteString(part)
			stmtBuf.WriteString("\n")

			if !isLast {
				// završio statement (na ';')
				flushStmt(stmtBuf.String())
				stmtBuf.Reset()
			}
		}
	}

	if err := sc2.Err(); err != nil {
		return nil, nil, err
	}

	// ako je ostalo nešto bez ';' na kraju
	if rest := strings.TrimSpace(stmtBuf.String()); rest != "" {
		flushStmt(rest)
	}

	// de-dupe (pg_dump ponekad duplira)
	fks = dedupeFKs(fks)

	allTables = make([]string, 0, len(tableSet))
	for t := range tableSet {
		allTables = append(allTables, t)
	}
	sort.Strings(allTables)

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

	return allTables, fks, nil
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

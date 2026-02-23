package planner

import (
	"bufio"
	crand "crypto/rand"
	"encoding/hex"
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"strings"
	"time"
)

// ==========================
// CONFIG + PUBLIC API
// ==========================

type DataGenConfig struct {
	// Ako ne navedeš specifične tabele, generator pravi DefaultRows za sve tabele (koje postoje u schema + plan).
	DefaultRows int

	// Specifično: table -> broj redova koje želiš.
	// Generator će automatski propagirati na parent tabele (da FK ima od čega birati).
	RequestedRows map[string]int

	// Koliko često nullable FK bude NULL (0.0 - 1.0)
	NullableFKNullRate float64

	// Seed za pseudo-random (ako 0, uzme time.Now)
	Seed int64
}

type GeneratedData struct {
	// table -> rows -> col -> sqlLiteral
	Rows map[string][]map[string]string

	// Za izbor FK vrijednosti: table -> col -> list of "registry values" (bez SQL navodnika)
	ValuesByTableCol map[string]map[string][]string
}

// FillFKNullability: sigurno popuni fk.IsNullable na osnovu CREATE TABLE kolona iz schema.
// Korisno jer FK definicija u ALTER TABLE ne kaže direktno NULL/NOT NULL, to je na koloni.
func FillFKNullability(schema *Schema, fks []ForeignKey) []ForeignKey {
	out := make([]ForeignKey, 0, len(fks))
	for _, fk := range fks {
		isNullable := fk.IsNullable
		t := schema.Tables[fk.ChildTable]
		if t != nil {
			for _, c := range t.Columns {
				if c.Name == fk.ChildColumn {
					isNullable = !c.NotNull
					break
				}
			}
		}
		fk.IsNullable = isNullable
		out = append(out, fk)
	}
	return out
}

// GenerateRandomData generiše INSERT podatke tako da FK-ovi budu validni.
// Radi po plan.InsertOrder (parent prije child).
// NOVO: enforce unique/PK constraint-e iz schema.UniqueConstraints da izbjegnemo duplikate.
func GenerateRandomData(schema *Schema, plan Plan, fks []ForeignKey, cfg DataGenConfig) (*GeneratedData, error) {
	if cfg.DefaultRows <= 0 {
		cfg.DefaultRows = 10
	}
	if cfg.NullableFKNullRate < 0 {
		cfg.NullableFKNullRate = 0
	}
	if cfg.NullableFKNullRate > 1 {
		cfg.NullableFKNullRate = 1
	}
	if cfg.Seed == 0 {
		cfg.Seed = time.Now().UnixNano()
	}
	rng := rand.New(rand.NewSource(cfg.Seed))

	// FK index: childTable -> []FK
	fkByChild := make(map[string][]ForeignKey)
	for _, fk := range fks {
		fkByChild[fk.ChildTable] = append(fkByChild[fk.ChildTable], fk)
	}

	required := computeRequiredRows(plan, fks, cfg)

	out := &GeneratedData{
		Rows:             make(map[string][]map[string]string),
		ValuesByTableCol: make(map[string]map[string][]string),
	}

	registerValue := func(table, col, sqlLit string) {
		v := stripQuotesForRegistry(sqlLit)
		if v == "NULL" {
			return
		}
		if _, ok := out.ValuesByTableCol[table]; !ok {
			out.ValuesByTableCol[table] = make(map[string][]string)
		}
		out.ValuesByTableCol[table][col] = append(out.ValuesByTableCol[table][col], v)
	}

	// Generiši redove po InsertOrder
	for _, tableName := range plan.InsertOrder {
		tbl := schema.Tables[tableName]
		if tbl == nil {
			continue
		}

		n := required[tableName]
		if n <= 0 {
			continue
		}

		// map FK kolona -> FK
		fkColMap := make(map[string]ForeignKey)
		for _, fk := range fkByChild[tableName] {
			fkColMap[fk.ChildColumn] = fk
		}

		// Unique constraints for this table (PK + UNIQUE)
		ucList := schema.UniqueConstraints[tableName]
		seen := make([]map[string]struct{}, len(ucList))
		for i := range seen {
			seen[i] = make(map[string]struct{})
		}

		rows := make([]map[string]string, 0, n)

		for i := 0; i < n; i++ {
			const maxAttempts = 2000

			var row map[string]string
			okRow := false

			for attempt := 0; attempt < maxAttempts; attempt++ {
				row = make(map[string]string, len(tbl.Columns))

				for _, c := range tbl.Columns {
					// FK kolona?
					if fk, ok := fkColMap[c.Name]; ok {
						val, err := pickFKValue(rng, out, fk, cfg.NullableFKNullRate)
						if err != nil {
							return nil, fmt.Errorf("FK value error for %s.%s: %w", tableName, c.Name, err)
						}
						row[c.Name] = val
						continue
					}

					val, err := randomValueForColumn(rng, schema, tableName, c)
					if err != nil {
						return nil, fmt.Errorf("value gen error for %s.%s: %w", tableName, c.Name, err)
					}
					row[c.Name] = val
				}

				// enforce UNIQUE/PK
				conflict := false
				for idx, cols := range ucList {
					k, ok := uniqueKeyForRow(row, cols)
					if !ok {
						continue
					}
					if _, exists := seen[idx][k]; exists {
						conflict = true
						break
					}
				}
				if conflict {
					continue
				}

				// reserve keys
				for idx, cols := range ucList {
					k, ok := uniqueKeyForRow(row, cols)
					if !ok {
						continue
					}
					seen[idx][k] = struct{}{}
				}

				okRow = true
				break
			}

			if !okRow {
				return nil, fmt.Errorf("could not generate unique row for table %s after many attempts; reduce rows or increase parent rows", tableName)
			}

			// tek sad registruj vrijednosti (da FK biranje radi, a da retry ne zagađuje registry)
			for _, c := range tbl.Columns {
				registerValue(tableName, c.Name, row[c.Name])
			}

			rows = append(rows, row)
		}

		out.Rows[tableName] = rows
	}

	return out, nil
}

// RenderInserts pravi SQL INSERT statements po plan.InsertOrder.
// Uključuje samo tabele koje imaju generisane redove.
func RenderInserts(schema *Schema, plan Plan, data *GeneratedData) string {
	var b strings.Builder

	for _, table := range plan.InsertOrder {
		rows := data.Rows[table]
		if len(rows) == 0 {
			continue
		}
		tbl := schema.Tables[table]
		if tbl == nil {
			continue
		}

		colNames := make([]string, 0, len(tbl.Columns))
		for _, c := range tbl.Columns {
			colNames = append(colNames, c.Name)
		}

		for _, row := range rows {
			b.WriteString("INSERT INTO ")
			b.WriteString(quoteIdentIfNeeded(table))
			b.WriteString(" (")

			for i, cn := range colNames {
				if i > 0 {
					b.WriteString(", ")
				}
				b.WriteString(quoteIdentIfNeeded(cn))
			}
			b.WriteString(") VALUES (")

			for i, cn := range colNames {
				if i > 0 {
					b.WriteString(", ")
				}
				v, ok := row[cn]
				if !ok {
					v = "NULL"
				}
				b.WriteString(v)
			}

			b.WriteString(");\n")
		}
		b.WriteString("\n")
	}

	return b.String()
}

// ==========================
// INTERNALS: REQUIRED ROWS
// ==========================

func computeRequiredRows(plan Plan, fks []ForeignKey, cfg DataGenConfig) map[string]int {
	required := make(map[string]int)

	// start from requested
	for t, n := range cfg.RequestedRows {
		tn := normalizeIdent(t)
		if n > required[tn] {
			required[tn] = n
		}
	}

	// if nothing requested -> generate DefaultRows for all in InsertOrder
	if len(required) == 0 {
		for _, t := range plan.InsertOrder {
			required[t] = cfg.DefaultRows
		}
		return required
	}

	// propagate: if child needs N -> parent needs >= N (so child can pick FK)
	changed := true
	for changed {
		changed = false
		for _, fk := range fks {
			childNeed := required[fk.ChildTable]
			if childNeed <= 0 {
				continue
			}
			parentNeed := childNeed
			if parentNeed > required[fk.ParentTable] {
				required[fk.ParentTable] = parentNeed
				changed = true
			}
		}
	}

	return required
}

// ==========================
// INTERNALS: UNIQUE/PK KEYING
// ==========================

// uniqueKeyForRow pravi stabilan ključ iz vrijednosti navedenih kolona.
// Vraća ok=false ako neka kolona fali ili je NULL.
// Napomena: UNIQUE u Postgresu dozvoljava više NULL-ova, pa NULL kombinacije ne enforce-amo.
// PRIMARY KEY kolone su NOT NULL, pa će tu ok biti true.
func uniqueKeyForRow(row map[string]string, cols []string) (key string, ok bool) {
	parts := make([]string, 0, len(cols))
	for _, c := range cols {
		v, exists := row[c]
		if !exists {
			return "", false
		}
		v = strings.TrimSpace(v)
		if v == "NULL" {
			return "", false
		}
		parts = append(parts, stripQuotesForRegistry(v))
	}
	return strings.Join(parts, "|"), true
}

// ==========================
// INTERNALS: FK PICKING
// ==========================

func pickFKValue(rng *rand.Rand, out *GeneratedData, fk ForeignKey, nullRate float64) (string, error) {
	if fk.IsNullable && rng.Float64() < nullRate {
		return "NULL", nil
	}

	if out.ValuesByTableCol[fk.ParentTable] == nil {
		return "", fmt.Errorf("no generated values for parent table %s yet", fk.ParentTable)
	}
	cands := out.ValuesByTableCol[fk.ParentTable][fk.ParentColumn]
	if len(cands) == 0 {
		return "", fmt.Errorf("no generated values for parent %s.%s yet", fk.ParentTable, fk.ParentColumn)
	}

	v := cands[rng.Intn(len(cands))]

	// SQL literal render
	if isUUID(v) {
		return fmt.Sprintf("'%s'", v), nil
	}
	if _, err := strconv.Atoi(v); err == nil {
		return v, nil
	}
	return fmt.Sprintf("'%s'", escapeSQLString(v)), nil
}

// ==========================
// INTERNALS: RANDOM VALUE GEN
// ==========================

func randomValueForColumn(rng *rand.Rand, schema *Schema, table string, c Column) (string, error) {
	typLower := strings.ToLower(c.Type)

	// ponekad NULL ako nije NOT NULL
	if !c.NotNull && rng.Float64() < 0.05 {
		return "NULL", nil
	}

	// enum?
	if vals, ok := schema.Enums[normalizeTypeName(c.Type)]; ok && len(vals) > 0 {
		v := vals[rng.Intn(len(vals))]
		return fmt.Sprintf("'%s'", escapeSQLString(v)), nil
	}

	switch typLower {
	case "uuid":
		u, err := newUUIDv4()
		if err != nil {
			return "", err
		}
		return fmt.Sprintf("'%s'", u), nil

	case "text":
		return fmt.Sprintf("'%s'", randomText(rng, 8, 18)), nil

	case "integer", "int", "int4":
		return strconv.Itoa(rng.Intn(5000)), nil

	case "bigint", "int8":
		x := int64(rng.Intn(2000000))
		return strconv.FormatInt(x, 10), nil

	case "double precision", "float8":
		v := rng.Float64() * 1000.0
		return strconv.FormatFloat(v, 'f', 6, 64), nil

	case "boolean", "bool":
		if rng.Intn(2) == 0 {
			return "FALSE", nil
		}
		return "TRUE", nil

	case "timestamp without time zone":
		t := randomTime(rng, 365*2)
		return fmt.Sprintf("'%s'", t.Format("2006-01-02 15:04:05")), nil

	case "time without time zone":
		h := rng.Intn(24)
		m := rng.Intn(60)
		s := rng.Intn(60)
		return fmt.Sprintf("'%02d:%02d:%02d'", h, m, s), nil

	case "date":
		d := randomTime(rng, 365*5).Format("2006-01-02")
		return fmt.Sprintf("'%s'", d), nil
	}

	// fallback: tretiraj kao text
	return fmt.Sprintf("'%s'", randomText(rng, 6, 14)), nil
}

func randomText(rng *rand.Rand, minLen, maxLen int) string {
	if maxLen < minLen {
		maxLen = minLen
	}
	n := minLen + rng.Intn(maxLen-minLen+1)
	const letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	b := make([]byte, n)
	for i := 0; i < n; i++ {
		b[i] = letters[rng.Intn(len(letters))]
	}
	return string(b)
}

func randomTime(rng *rand.Rand, pastDays int) time.Time {
	now := time.Now()
	secs := int64(rng.Intn(pastDays*24*3600 + 1))
	return now.Add(-time.Duration(secs) * time.Second)
}

// UUIDv4 bez eksterne biblioteke
func newUUIDv4() (string, error) {
	var b [16]byte
	_, err := crand.Read(b[:])
	if err != nil {
		return "", err
	}
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80

	hexs := hex.EncodeToString(b[:])
	return fmt.Sprintf("%s-%s-%s-%s-%s",
		hexs[0:8], hexs[8:12], hexs[12:16], hexs[16:20], hexs[20:32],
	), nil
}

func isUUID(s string) bool {
	if len(s) != 36 {
		return false
	}
	for i, ch := range s {
		switch i {
		case 8, 13, 18, 23:
			if ch != '-' {
				return false
			}
		default:
			if !((ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F')) {
				return false
			}
		}
	}
	return true
}

func escapeSQLString(s string) string {
	return strings.ReplaceAll(s, "'", "''")
}

func stripQuotesForRegistry(sqlLit string) string {
	sqlLit = strings.TrimSpace(sqlLit)
	if sqlLit == "NULL" {
		return sqlLit
	}
	if strings.HasPrefix(sqlLit, "'") && strings.HasSuffix(sqlLit, "'") && len(sqlLit) >= 2 {
		return strings.TrimSuffix(strings.TrimPrefix(sqlLit, "'"), "'")
	}
	return sqlLit
}

// quote ident minimalno: quote ako je reserved "user" ili ima čudne karaktere
func quoteIdentIfNeeded(ident string) string {
	if strings.EqualFold(ident, "user") {
		return `"user"`
	}
	for _, ch := range ident {
		if !(ch == '_' || (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9')) {
			return `"` + strings.ReplaceAll(ident, `"`, `""`) + `"`
		}
	}
	return ident
}

// ==========================
// OPTIONAL: Small helper to stream SQL to file easily
// ==========================

func WriteSQLFile(path string, sql string) error {
	w, err := osCreateTrunc(path)
	if err != nil {
		return err
	}
	defer w.Close()

	bw := bufio.NewWriter(w)
	_, err = bw.WriteString(sql)
	if err != nil {
		return err
	}
	return bw.Flush()
}

// odvojeno da ne kolidira s os.* u drugim fajlovima (ako imaš)
type writeCloser interface {
	Write([]byte) (int, error)
	Close() error
}

func osCreateTrunc(path string) (writeCloser, error) {
	return os.Create(path)
}

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
	DefaultRows int

	RequestedRows map[string]int

	NullableFKNullRate float64

	Seed int64
}

type GeneratedData struct {
	Rows map[string][]map[string]string

	ValuesByTableCol map[string]map[string][]string
}

// FillFKNullability: popuni fk.IsNullable na osnovu CREATE TABLE kolona iz schema.
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

// GenerateRandomData generiše INSERT podatke tako da FK-ovi budu validni,
// UNIQUE/PK ne budu prekršeni, i CHECK constraint-i budu zadovoljeni (DINAMIČKI iz schema.CheckConstraints).
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

	// pre-compile CHECK constraints per table into AST (faster + cleaner errors)
	checkAST := make(map[string][]checkNode)
	for _, t := range plan.InsertOrder {
		raw := schema.CheckConstraints[t]
		if len(raw) == 0 {
			continue
		}
		nodes := make([]checkNode, 0, len(raw))
		for _, expr := range raw {
			n, err := parseCheckExpr(expr)
			if err != nil {
				return nil, fmt.Errorf("failed to parse CHECK for table %s: %s: %w", t, expr, err)
			}
			nodes = append(nodes, n)
		}
		checkAST[t] = nodes
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
		seenUnique := make([]map[string]struct{}, len(ucList))
		for i := range seenUnique {
			seenUnique[i] = make(map[string]struct{})
		}

		rows := make([]map[string]string, 0, n)

		for i := 0; i < n; i++ {
			const maxAttempts = 5000
			var row map[string]string
			okRow := false

			for attempt := 0; attempt < maxAttempts; attempt++ {
				row = make(map[string]string, len(tbl.Columns))

				// 1) generate columns
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

				// 2) CHECK constraints (dinamički)
				if asts := checkAST[tableName]; len(asts) > 0 {
					pass := true
					for _, ast := range asts {
						ok, unknown, err := evalCheck(ast, schema, tableName, row)
						if err != nil {
							return nil, fmt.Errorf("CHECK eval error for table %s: %w", tableName, err)
						}
						// PostgreSQL semantics: CHECK passes if expression is TRUE or NULL (unknown).
						// It fails only if expression is FALSE.
						if !ok && !unknown {
							pass = false
							break
						}
					}
					if !pass {
						continue
					}
				}

				// 3) UNIQUE/PK constraints
				conflict := false
				for idx, cols := range ucList {
					k, ok := uniqueKeyForRow(row, cols)
					if !ok {
						continue // NULL -> allowed for UNIQUE in PG
					}
					if _, exists := seenUnique[idx][k]; exists {
						conflict = true
						break
					}
				}
				if conflict {
					continue
				}

				// reserve unique keys
				for idx, cols := range ucList {
					k, ok := uniqueKeyForRow(row, cols)
					if !ok {
						continue
					}
					seenUnique[idx][k] = struct{}{}
				}

				okRow = true
				break
			}

			if !okRow {
				return nil, fmt.Errorf("could not generate valid row for table %s after many attempts; reduce rows or increase parent rows", tableName)
			}

			// register after acceptance (da retry ne zagađuje registry)
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

	for t, n := range cfg.RequestedRows {
		tn := normalizeIdent(t)
		if n > required[tn] {
			required[tn] = n
		}
	}

	if len(required) == 0 {
		for _, t := range plan.InsertOrder {
			required[t] = cfg.DefaultRows
		}
		return required
	}

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

// UNIQUE in Postgres allows multiple NULLs; PRIMARY KEY doesn't have NULLs anyway.
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

	// sometimes NULL if allowed
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

	// fallback
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

// UUIDv4
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

// quote ident minimalno
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
// FILE WRITE helper
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

type writeCloser interface {
	Write([]byte) (int, error)
	Close() error
}

func osCreateTrunc(path string) (writeCloser, error) {
	return os.Create(path)
}

// ==========================
// CHECK CONSTRAINT: PARSER + EVALUATOR (DINAMIČKI)
// ==========================

type tokenType int

const (
	tEOF tokenType = iota
	tIdent
	tString
	tNumber
	tBool
	tNull

	tLParen
	tRParen

	tAnd
	tOr
	tNot
	tIs

	tEq
	tNeq
	tGt
	tGte
	tLt
	tLte
)

type token struct {
	typ tokenType
	lit string
}

type lexer struct {
	s   string
	i   int
	n   int
	up  string
	err error
}

func newLexer(s string) *lexer {
	return &lexer{s: s, up: strings.ToUpper(s), n: len(s)}
}

func (l *lexer) skipWS() {
	for l.i < l.n {
		ch := l.s[l.i]
		if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
			l.i++
			continue
		}
		break
	}
}

func (l *lexer) next() token {
	l.skipWS()
	if l.i >= l.n {
		return token{typ: tEOF}
	}

	ch := l.s[l.i]

	// parentheses
	if ch == '(' {
		l.i++
		return token{typ: tLParen, lit: "("}
	}
	if ch == ')' {
		l.i++
		return token{typ: tRParen, lit: ")"}
	}

	// operators
	if ch == '=' {
		l.i++
		return token{typ: tEq, lit: "="}
	}
	if ch == '!' && l.i+1 < l.n && l.s[l.i+1] == '=' {
		l.i += 2
		return token{typ: tNeq, lit: "!="}
	}
	if ch == '>' {
		if l.i+1 < l.n && l.s[l.i+1] == '=' {
			l.i += 2
			return token{typ: tGte, lit: ">="}
		}
		l.i++
		return token{typ: tGt, lit: ">"}
	}
	if ch == '<' {
		if l.i+1 < l.n && l.s[l.i+1] == '=' {
			l.i += 2
			return token{typ: tLte, lit: "<="}
		}
		l.i++
		return token{typ: tLt, lit: "<"}
	}

	// string literal
	if ch == '\'' {
		l.i++
		start := l.i
		var b strings.Builder
		for l.i < l.n {
			c := l.s[l.i]
			if c == '\'' {
				// doubled '' inside string
				if l.i+1 < l.n && l.s[l.i+1] == '\'' {
					b.WriteString(l.s[start:l.i])
					b.WriteByte('\'')
					l.i += 2
					start = l.i
					continue
				}
				// end string
				b.WriteString(l.s[start:l.i])
				l.i++
				// optional cast ::type -> skip it
				l.skipWS()
				if l.i+1 < l.n && l.s[l.i] == ':' && l.s[l.i+1] == ':' {
					l.i += 2
					// skip type name tokens (public.xxx)
					for l.i < l.n {
						c2 := l.s[l.i]
						if (c2 >= 'a' && c2 <= 'z') || (c2 >= 'A' && c2 <= 'Z') || (c2 >= '0' && c2 <= '9') || c2 == '_' || c2 == '.' || c2 == '"' {
							l.i++
							continue
						}
						break
					}
				}
				return token{typ: tString, lit: b.String()}
			}
			l.i++
		}
		l.err = fmt.Errorf("unterminated string literal")
		return token{typ: tEOF}
	}

	// number (integer)
	if (ch >= '0' && ch <= '9') || (ch == '-' && l.i+1 < l.n && l.s[l.i+1] >= '0' && l.s[l.i+1] <= '9') {
		start := l.i
		l.i++
		for l.i < l.n {
			c := l.s[l.i]
			if c >= '0' && c <= '9' {
				l.i++
				continue
			}
			break
		}
		return token{typ: tNumber, lit: strings.TrimSpace(l.s[start:l.i])}
	}

	// identifier / keyword
	if (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_' || ch == '"' {
		start := l.i
		l.i++
		for l.i < l.n {
			c := l.s[l.i]
			if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == '.' || c == '"' {
				l.i++
				continue
			}
			break
		}
		raw := strings.TrimSpace(l.s[start:l.i])
		raw = strings.Trim(raw, `"`)
		up := strings.ToUpper(raw)

		switch up {
		case "AND":
			return token{typ: tAnd, lit: "AND"}
		case "OR":
			return token{typ: tOr, lit: "OR"}
		case "NOT":
			return token{typ: tNot, lit: "NOT"}
		case "IS":
			return token{typ: tIs, lit: "IS"}
		case "NULL":
			return token{typ: tNull, lit: "NULL"}
		case "TRUE", "FALSE":
			return token{typ: tBool, lit: up}
		}

		return token{typ: tIdent, lit: normalizeIdent(raw)}
	}

	// unknown char -> skip
	l.i++
	return l.next()
}

type parser struct {
	l   *lexer
	cur token
}

func parseCheckExpr(expr string) (checkNode, error) {
	p := &parser{l: newLexer(expr)}
	p.cur = p.l.next()
	n, err := p.parseOr()
	if err != nil {
		return nil, err
	}
	if p.l.err != nil {
		return nil, p.l.err
	}
	return n, nil
}

func (p *parser) eat(tt tokenType) (token, bool) {
	if p.cur.typ == tt {
		t := p.cur
		p.cur = p.l.next()
		return t, true
	}
	return token{}, false
}

func (p *parser) expect(tt tokenType) (token, error) {
	t, ok := p.eat(tt)
	if !ok {
		return token{}, fmt.Errorf("expected token %v, got %v (%s)", tt, p.cur.typ, p.cur.lit)
	}
	return t, nil
}

func (p *parser) parseOr() (checkNode, error) {
	left, err := p.parseAnd()
	if err != nil {
		return nil, err
	}
	for p.cur.typ == tOr {
		p.cur = p.l.next()
		right, err := p.parseAnd()
		if err != nil {
			return nil, err
		}
		left = &binNode{op: tOr, l: left, r: right}
	}
	return left, nil
}

func (p *parser) parseAnd() (checkNode, error) {
	left, err := p.parseNot()
	if err != nil {
		return nil, err
	}
	for p.cur.typ == tAnd {
		p.cur = p.l.next()
		right, err := p.parseNot()
		if err != nil {
			return nil, err
		}
		left = &binNode{op: tAnd, l: left, r: right}
	}
	return left, nil
}

func (p *parser) parseNot() (checkNode, error) {
	if p.cur.typ == tNot {
		p.cur = p.l.next()
		n, err := p.parseNot()
		if err != nil {
			return nil, err
		}
		return &notNode{n: n}, nil
	}
	return p.parseCmpOrGroup()
}

func (p *parser) parseCmpOrGroup() (checkNode, error) {
	if p.cur.typ == tLParen {
		p.cur = p.l.next()
		n, err := p.parseOr()
		if err != nil {
			return nil, err
		}
		if _, err := p.expect(tRParen); err != nil {
			return nil, err
		}
		return n, nil
	}

	// left operand
	left, err := p.parseValue()
	if err != nil {
		return nil, err
	}

	// IS [NOT] NULL
	if p.cur.typ == tIs {
		p.cur = p.l.next()
		not := false
		if p.cur.typ == tNot {
			not = true
			p.cur = p.l.next()
		}
		if p.cur.typ != tNull {
			return nil, fmt.Errorf("expected NULL after IS/IS NOT, got %v (%s)", p.cur.typ, p.cur.lit)
		}
		p.cur = p.l.next()
		return &isNullNode{v: left, not: not}, nil
	}

	// comparison op
	switch p.cur.typ {
	case tEq, tNeq, tGt, tGte, tLt, tLte:
		op := p.cur.typ
		p.cur = p.l.next()
		right, err := p.parseValue()
		if err != nil {
			return nil, err
		}
		return &cmpNode{op: op, l: left, r: right}, nil
	default:
		// bare value in boolean context
		return &truthyNode{v: left}, nil
	}
}

func (p *parser) parseValue() (valueNode, error) {
	switch p.cur.typ {
	case tIdent:
		t := p.cur
		p.cur = p.l.next()
		// handle qualified idents like public.table.column -> normalizeIdent already kept last part when used elsewhere,
		// but here lexer gives normalizeIdent(raw) which strips schema/table if dot exists.
		// still: if dot remains, normalizeIdent will keep last part.
		return valueNode{kind: vkIdent, lit: normalizeIdent(t.lit)}, nil
	case tString:
		t := p.cur
		p.cur = p.l.next()
		return valueNode{kind: vkString, lit: t.lit}, nil
	case tNumber:
		t := p.cur
		p.cur = p.l.next()
		return valueNode{kind: vkNumber, lit: t.lit}, nil
	case tBool:
		t := p.cur
		p.cur = p.l.next()
		return valueNode{kind: vkBool, lit: t.lit}, nil
	case tNull:
		p.cur = p.l.next()
		return valueNode{kind: vkNull, lit: "NULL"}, nil
	case tLParen:
		// shouldn't happen here; caller handles groups
		return valueNode{}, fmt.Errorf("unexpected '(' in value")
	default:
		return valueNode{}, fmt.Errorf("unexpected token in value: %v (%s)", p.cur.typ, p.cur.lit)
	}
}

type checkNode interface {
	eval(schema *Schema, table string, row map[string]string) (val triBool, err error)
}

type triBool int

const (
	tbFalse triBool = iota
	tbTrue
	tbUnknown // SQL NULL
)

type binNode struct {
	op tokenType
	l  checkNode
	r  checkNode
}

func (n *binNode) eval(schema *Schema, table string, row map[string]string) (triBool, error) {
	a, err := n.l.eval(schema, table, row)
	if err != nil {
		return tbFalse, err
	}
	b, err := n.r.eval(schema, table, row)
	if err != nil {
		return tbFalse, err
	}

	switch n.op {
	case tAnd:
		// SQL 3-valued logic
		if a == tbFalse || b == tbFalse {
			return tbFalse, nil
		}
		if a == tbUnknown || b == tbUnknown {
			return tbUnknown, nil
		}
		return tbTrue, nil
	case tOr:
		if a == tbTrue || b == tbTrue {
			return tbTrue, nil
		}
		if a == tbUnknown || b == tbUnknown {
			return tbUnknown, nil
		}
		return tbFalse, nil
	default:
		return tbFalse, fmt.Errorf("unknown bin op %v", n.op)
	}
}

type notNode struct {
	n checkNode
}

func (n *notNode) eval(schema *Schema, table string, row map[string]string) (triBool, error) {
	v, err := n.n.eval(schema, table, row)
	if err != nil {
		return tbFalse, err
	}
	if v == tbUnknown {
		return tbUnknown, nil
	}
	if v == tbTrue {
		return tbFalse, nil
	}
	return tbTrue, nil
}

type cmpNode struct {
	op tokenType
	l  valueNode
	r  valueNode
}

func (n *cmpNode) eval(schema *Schema, table string, row map[string]string) (triBool, error) {
	lv, lok, err := n.l.resolve(schema, table, row)
	if err != nil {
		return tbFalse, err
	}
	rv, rok, err := n.r.resolve(schema, table, row)
	if err != nil {
		return tbFalse, err
	}
	if !lok || !rok {
		return tbUnknown, nil
	}

	// compare with type-aware coercion
	cmp, ok, err := compareScalar(lv, rv)
	if err != nil {
		return tbFalse, err
	}
	if !ok {
		return tbUnknown, nil
	}

	switch n.op {
	case tEq:
		if cmp == 0 {
			return tbTrue, nil
		}
		return tbFalse, nil
	case tNeq:
		if cmp != 0 {
			return tbTrue, nil
		}
		return tbFalse, nil
	case tGt:
		if cmp > 0 {
			return tbTrue, nil
		}
		return tbFalse, nil
	case tGte:
		if cmp >= 0 {
			return tbTrue, nil
		}
		return tbFalse, nil
	case tLt:
		if cmp < 0 {
			return tbTrue, nil
		}
		return tbFalse, nil
	case tLte:
		if cmp <= 0 {
			return tbTrue, nil
		}
		return tbFalse, nil
	default:
		return tbFalse, fmt.Errorf("unknown cmp op %v", n.op)
	}
}

type isNullNode struct {
	v   valueNode
	not bool
}

func (n *isNullNode) eval(schema *Schema, table string, row map[string]string) (triBool, error) {
	_, ok, err := n.v.resolve(schema, table, row)
	if err != nil {
		return tbFalse, err
	}
	// ok==false means NULL
	isNull := !ok
	if n.not {
		if isNull {
			return tbFalse, nil
		}
		return tbTrue, nil
	}
	if isNull {
		return tbTrue, nil
	}
	return tbFalse, nil
}

type truthyNode struct {
	v valueNode
}

func (n *truthyNode) eval(schema *Schema, table string, row map[string]string) (triBool, error) {
	v, ok, err := n.v.resolve(schema, table, row)
	if err != nil {
		return tbFalse, err
	}
	if !ok {
		return tbUnknown, nil
	}
	// only booleans make sense here; else treat non-empty as TRUE
	up := strings.ToUpper(v)
	if up == "TRUE" {
		return tbTrue, nil
	}
	if up == "FALSE" {
		return tbFalse, nil
	}
	if v == "" {
		return tbFalse, nil
	}
	return tbTrue, nil
}

type valueKind int

const (
	vkIdent valueKind = iota
	vkString
	vkNumber
	vkBool
	vkNull
)

type valueNode struct {
	kind valueKind
	lit  string
}

// resolve returns (scalarString, isNotNull, error)
func (v valueNode) resolve(schema *Schema, table string, row map[string]string) (string, bool, error) {
	switch v.kind {
	case vkNull:
		return "", false, nil
	case vkString:
		return v.lit, true, nil
	case vkNumber:
		return v.lit, true, nil
	case vkBool:
		return strings.ToUpper(v.lit), true, nil
	case vkIdent:
		col := normalizeIdent(v.lit)
		sqlLit, ok := row[col]
		if !ok {
			// unknown identifier -> treat as NULL (so check becomes UNKNOWN -> pass)
			return "", false, nil
		}
		sqlLit = strings.TrimSpace(sqlLit)
		if sqlLit == "NULL" {
			return "", false, nil
		}
		raw := stripQuotesForRegistry(sqlLit)
		// keep TRUE/FALSE uppercase for boolean
		if strings.EqualFold(raw, "true") {
			return "TRUE", true, nil
		}
		if strings.EqualFold(raw, "false") {
			return "FALSE", true, nil
		}
		return raw, true, nil
	default:
		return "", false, fmt.Errorf("unknown value kind")
	}
}

// compareScalar returns cmp (-1/0/1), ok=false means cannot compare -> UNKNOWN
func compareScalar(a, b string) (cmp int, ok bool, err error) {
	// Try timestamp first
	if ta, ea := parseTimestamp(a); ea == nil {
		if tb, eb := parseTimestamp(b); eb == nil {
			if ta.Before(tb) {
				return -1, true, nil
			}
			if ta.After(tb) {
				return 1, true, nil
			}
			return 0, true, nil
		}
	}
	// Try date
	if da, ea := parseDate(a); ea == nil {
		if db, eb := parseDate(b); eb == nil {
			if da.Before(db) {
				return -1, true, nil
			}
			if da.After(db) {
				return 1, true, nil
			}
			return 0, true, nil
		}
	}
	// Try time
	if ta, ea := parseTimeOnly(a); ea == nil {
		if tb, eb := parseTimeOnly(b); eb == nil {
			if ta < tb {
				return -1, true, nil
			}
			if ta > tb {
				return 1, true, nil
			}
			return 0, true, nil
		}
	}

	// Try int
	if ia, ea := strconv.ParseInt(a, 10, 64); ea == nil {
		if ib, eb := strconv.ParseInt(b, 10, 64); eb == nil {
			if ia < ib {
				return -1, true, nil
			}
			if ia > ib {
				return 1, true, nil
			}
			return 0, true, nil
		}
	}

	// Try float
	if fa, ea := strconv.ParseFloat(a, 64); ea == nil {
		if fb, eb := strconv.ParseFloat(b, 64); eb == nil {
			if fa < fb {
				return -1, true, nil
			}
			if fa > fb {
				return 1, true, nil
			}
			return 0, true, nil
		}
	}

	// Try bool equality/inequality
	ua := strings.ToUpper(a)
	ub := strings.ToUpper(b)
	if (ua == "TRUE" || ua == "FALSE") && (ub == "TRUE" || ub == "FALSE") {
		ba := ua == "TRUE"
		bb := ub == "TRUE"
		if ba == bb {
			return 0, true, nil
		}
		if !ba && bb {
			return -1, true, nil
		}
		return 1, true, nil
	}

	// fallback: string compare
	if a < b {
		return -1, true, nil
	}
	if a > b {
		return 1, true, nil
	}
	return 0, true, nil
}

func parseTimestamp(s string) (time.Time, error) {
	// accept "2006-01-02 15:04:05" and "2006-01-02 15:04:05.999999"
	layouts := []string{
		"2006-01-02 15:04:05",
		"2006-01-02 15:04:05.999999",
	}
	for _, l := range layouts {
		if t, err := time.ParseInLocation(l, s, time.Local); err == nil {
			return t, nil
		}
	}
	return time.Time{}, fmt.Errorf("not timestamp")
}

func parseDate(s string) (time.Time, error) {
	t, err := time.ParseInLocation("2006-01-02", s, time.Local)
	if err != nil {
		return time.Time{}, err
	}
	return t, nil
}

// parseTimeOnly -> seconds from midnight
func parseTimeOnly(s string) (int, error) {
	parts := strings.Split(s, ":")
	if len(parts) != 3 {
		return 0, fmt.Errorf("not time")
	}
	h, err := strconv.Atoi(parts[0])
	if err != nil {
		return 0, err
	}
	m, err := strconv.Atoi(parts[1])
	if err != nil {
		return 0, err
	}
	sec, err := strconv.Atoi(parts[2])
	if err != nil {
		return 0, err
	}
	if h < 0 || h > 23 || m < 0 || m > 59 || sec < 0 || sec > 59 {
		return 0, fmt.Errorf("invalid time")
	}
	return h*3600 + m*60 + sec, nil
}

// evalCheck returns ok=true if expression evaluates to TRUE,
// unknown=true if expression evaluates to NULL,
// (ok=false, unknown=false) means FALSE (constraint violation).
func evalCheck(ast checkNode, schema *Schema, table string, row map[string]string) (ok bool, unknown bool, err error) {
	v, err := ast.eval(schema, table, row)
	if err != nil {
		return false, false, err
	}
	if v == tbUnknown {
		return false, true, nil
	}
	if v == tbTrue {
		return true, false, nil
	}
	return false, false, nil
}

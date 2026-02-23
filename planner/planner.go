package planner

import "sort"

// ForeignKey opisuje FK vezu: child.childColumn -> parent.parentColumn
type ForeignKey struct {
	ChildTable   string
	ChildColumn  string
	ParentTable  string
	ParentColumn string
	// Ako želiš kasnije 2-pass po koloni:
	IsNullable bool // da li child FK kolona može biti NULL (pomaže u ciklusima)
}

// Graph je usmjereni graf tabela.
// Edges: from -> to znači "from mora prije to" (parent -> child).
type Graph struct {
	Nodes map[string]struct{}
	Edges map[string]map[string]struct{} // adjacency set
	InDeg map[string]int                 // indegree za Kahn topo
}

func NewGraph() *Graph {
	return &Graph{
		Nodes: make(map[string]struct{}),
		Edges: make(map[string]map[string]struct{}),
		InDeg: make(map[string]int),
	}
}

func (g *Graph) ensureNode(n string) {
	if _, ok := g.Nodes[n]; !ok {
		g.Nodes[n] = struct{}{}
	}
	if _, ok := g.Edges[n]; !ok {
		g.Edges[n] = make(map[string]struct{})
	}
	if _, ok := g.InDeg[n]; !ok {
		g.InDeg[n] = 0
	}
}

// AddEdge dodaje ivicu from -> to (from mora biti prije to).
func (g *Graph) AddEdge(from, to string) {
	g.ensureNode(from)
	g.ensureNode(to)

	// izbjegni duplikate da indegree ne ode u nebesa
	if _, exists := g.Edges[from][to]; exists {
		return
	}
	g.Edges[from][to] = struct{}{}
	g.InDeg[to]++
}

// BuildGraphFromFK pravi graf iz FK lista.
// parent -> child
func BuildGraphFromFK(fks []ForeignKey) *Graph {
	g := NewGraph()
	for _, fk := range fks {
		// osiguraj čvorove i ivicu parent->child
		g.AddEdge(fk.ParentTable, fk.ChildTable)
		// ako ima tabela bez ijedne veze, ubaci je eksplicitno (ako znaš listu svih tabela)
		// ovdje je minimalno: čvorovi se pojavljuju kroz FK.
	}
	return g
}

// TopoResult vraća topološki redoslijed + koje tabele nisu mogle u redoslijed (zbog ciklusa).
type TopoResult struct {
	Order      []string
	Unresolved []string // čvorovi koji nisu skinuti (u ciklusu ili zavise od ciklusa)
}

// TopologicalSortKahn radi Kahn-ov algoritam.
// Determinizam: uzimamo najmanji lex node kad ih ima više sa indegree=0.
func TopologicalSortKahn(g *Graph) TopoResult {
	// kopija indegree jer ćemo ga mijenjati
	indeg := make(map[string]int, len(g.InDeg))
	for n, d := range g.InDeg {
		indeg[n] = d
	}

	zero := make([]string, 0)
	for n := range g.Nodes {
		if indeg[n] == 0 {
			zero = append(zero, n)
		}
	}
	sort.Strings(zero)

	order := make([]string, 0, len(g.Nodes))

	popMin := func() string {
		// zero je sortiran
		n := zero[0]
		zero = zero[1:]
		return n
	}

	insertSorted := func(n string) {
		// ubaci n u sortirani slice zero
		i := sort.SearchStrings(zero, n)
		zero = append(zero, "")
		copy(zero[i+1:], zero[i:])
		zero[i] = n
	}

	for len(zero) > 0 {
		n := popMin()
		order = append(order, n)

		for to := range g.Edges[n] {
			indeg[to]--
			if indeg[to] == 0 {
				insertSorted(to)
			}
		}
	}

	if len(order) == len(g.Nodes) {
		return TopoResult{Order: order, Unresolved: nil}
	}

	// unresolved = čvorovi koji nisu u order
	inOrder := make(map[string]struct{}, len(order))
	for _, n := range order {
		inOrder[n] = struct{}{}
	}

	unresolved := make([]string, 0)
	for n := range g.Nodes {
		if _, ok := inOrder[n]; !ok {
			unresolved = append(unresolved, n)
		}
	}
	sort.Strings(unresolved)

	return TopoResult{Order: order, Unresolved: unresolved}
}

func BuildPlanWithTables(allTables []string, fks []ForeignKey) (Plan, error) {
	g := NewGraph()

	for _, t := range allTables {
		g.ensureNode(t)
	}
	for _, fk := range fks {
		g.AddEdge(fk.ParentTable, fk.ChildTable)
	}

	topo := TopologicalSortKahn(g)
	scc := TarjanSCC(g)

	twoPass := make(map[string]struct{})
	for _, cyc := range scc.Cycles {
		for _, t := range cyc {
			twoPass[t] = struct{}{}
		}
	}

	return Plan{
		InsertOrder: topo.Order,
		TwoPass:     twoPass,
		Cycles:      scc.Cycles,
		Unresolved:  topo.Unresolved,
	}, nil
}

package planner

import "sort"

type Plan struct {
	InsertOrder []string            // redoslijed (koliko god može)
	TwoPass     map[string]struct{} // tabele koje su u ciklusu
	Cycles      [][]string          // SCC ciklusi radi debug-a
	Unresolved  []string            // iz topo, radi info
}

func BuildPlan(fks []ForeignKey) (Plan, error) {
	g := BuildGraphFromFK(fks)

	topo := TopologicalSortKahn(g)
	scc := TarjanSCC(g)

	twoPass := make(map[string]struct{})
	for _, cyc := range scc.Cycles {
		for _, t := range cyc {
			twoPass[t] = struct{}{}
		}
	}

	// Ako hoćeš, možeš “nadograditi” insertOrder tako da unresolved (ciklični) idu na kraj,
	// ali to nema smisla bez 2-pass logike; ovdje samo dajemo što topo može.
	order := topo.Order

	// Stabilan output
	unres := append([]string(nil), topo.Unresolved...)
	sort.Strings(unres)

	return Plan{
		InsertOrder: order,
		TwoPass:     twoPass,
		Cycles:      scc.Cycles,
		Unresolved:  unres,
	}, nil
}

func (p Plan) IsTwoPass(table string) bool {
	_, ok := p.TwoPass[table]
	return ok
}

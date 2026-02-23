package planner

import "sort"

// SCCResult sadrži sve SCC komponente + koje su ciklične.
type SCCResult struct {
	Components [][]string
	Cycles     [][]string // samo SCC koje predstavljaju ciklus
}

// TarjanSCC pronalazi strongly connected components.
// Determinizam: sortira output komponente i njihov sadržaj.
func TarjanSCC(g *Graph) SCCResult {
	index := 0
	stack := make([]string, 0)
	onStack := make(map[string]bool, len(g.Nodes))

	indices := make(map[string]int, len(g.Nodes))
	lowlink := make(map[string]int, len(g.Nodes))
	for n := range g.Nodes {
		indices[n] = -1
	}

	var comps [][]string

	var strongconnect func(v string)
	strongconnect = func(v string) {
		indices[v] = index
		lowlink[v] = index
		index++

		stack = append(stack, v)
		onStack[v] = true

		// deterministički obilazak susjeda
		neighbors := make([]string, 0, len(g.Edges[v]))
		for w := range g.Edges[v] {
			neighbors = append(neighbors, w)
		}
		sort.Strings(neighbors)

		for _, w := range neighbors {
			if indices[w] == -1 {
				strongconnect(w)
				if lowlink[w] < lowlink[v] {
					lowlink[v] = lowlink[w]
				}
			} else if onStack[w] {
				if indices[w] < lowlink[v] {
					lowlink[v] = indices[w]
				}
			}
		}

		// root SCC
		if lowlink[v] == indices[v] {
			comp := make([]string, 0)
			for {
				n := stack[len(stack)-1]
				stack = stack[:len(stack)-1]
				onStack[n] = false
				comp = append(comp, n)
				if n == v {
					break
				}
			}
			sort.Strings(comp)
			comps = append(comps, comp)
		}
	}

	// deterministički start po sortiranom listu čvorova
	nodes := make([]string, 0, len(g.Nodes))
	for n := range g.Nodes {
		nodes = append(nodes, n)
	}
	sort.Strings(nodes)

	for _, v := range nodes {
		if indices[v] == -1 {
			strongconnect(v)
		}
	}

	// ciklusi = SCC size>1 ili size==1 sa self-loop
	cycles := make([][]string, 0)
	for _, c := range comps {
		if len(c) > 1 {
			cycles = append(cycles, c)
			continue
		}
		only := c[0]
		if _, ok := g.Edges[only][only]; ok {
			cycles = append(cycles, c)
		}
	}

	// sort komponente po prvom elementu radi stabilnosti
	sort.Slice(comps, func(i, j int) bool {
		return comps[i][0] < comps[j][0]
	})
	sort.Slice(cycles, func(i, j int) bool {
		return cycles[i][0] < cycles[j][0]
	})

	return SCCResult{Components: comps, Cycles: cycles}
}

package main

import (
	"fmt"
	"os"
	"sort"

	"root/planner"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Println("Usage: go run . ./schema.sql")
		os.Exit(1)
	}

	schemaPath := os.Args[1]

	allTables, fks, err := planner.ParseSchemaSQL(schemaPath)
	if err != nil {
		panic(err)
	}

	// Stabilan prikaz
	sort.Strings(allTables)

	fmt.Println("Tables:", len(allTables))
	fmt.Println("FKs:", len(fks))

	plan, err := planner.BuildPlanWithTables(allTables, fks)
	if err != nil {
		panic(err)
	}

	fmt.Println("\nInsert order:", plan.InsertOrder)
	fmt.Println("Unresolved:", plan.Unresolved)
	fmt.Println("Cycles:", plan.Cycles)

	fmt.Println("\nTwo-pass tables:")
	keys := make([]string, 0, len(plan.TwoPass))
	for t := range plan.TwoPass {
		keys = append(keys, t)
	}
	sort.Strings(keys)
	for _, t := range keys {
		fmt.Println(" -", t)
	}
}

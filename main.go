package main

import (
	"flag"
	"fmt"
	"os"
	"sort"

	"root/planner"
)

func main() {
	// CLI flags
	outPath := flag.String("out", "out.sql", "Output SQL file for generated INSERTs")
	rows := flag.Int("rows", 10, "Rows to generate for --table (and propagated dependencies)")
	table := flag.String("table", "", "Target table to generate rows for (e.g. visit_service_item). If empty, generates default rows for all tables.")
	seed := flag.Int64("seed", 0, "Random seed (0 = time-based)")
	nullRate := flag.Float64("nullRate", 0.20, "Nullable FK NULL rate (0.0 - 1.0)")
	printOnly := flag.Bool("printPlan", false, "Only print tables/FKs/plan, do not generate data")
	flag.Parse()

	if flag.NArg() != 1 {
		fmt.Println("Usage:")
		fmt.Println("  go run . ./schema.sql")
		fmt.Println("  go run . ./schema.sql --out out.sql --table visit_service_item --rows 10")
		fmt.Println("Flags:")
		flag.PrintDefaults()
		os.Exit(1)
	}

	schemaPath := flag.Arg(0)

	// 1) Parse pg_dump -> schema + allTables + fks
	schema, allTables, fks, err := planner.ParsePgDumpAll(schemaPath)
	if err != nil {
		panic(err)
	}

	sort.Strings(allTables)

	fmt.Println("\nUnique constraints for additional_information_business:")
	ucs := schema.UniqueConstraints["additional_information_business"]
	fmt.Println("count:", len(ucs))
	for i, uc := range ucs {
		fmt.Printf("  %d) %v\n", i+1, uc)
	}

	fmt.Println("Tables:", len(allTables))
	fmt.Println("FKs:", len(fks))
	fmt.Println("Enums:", len(schema.Enums))

	// 2) Build plan (topo order)
	plan, err := planner.BuildPlanWithTables(allTables, fks)
	if err != nil {
		panic(err)
	}

	fmt.Println("\nInsert order:", plan.InsertOrder)
	fmt.Println("Unresolved:", plan.Unresolved)
	fmt.Println("Cycles:", plan.Cycles)

	if *printOnly {
		return
	}

	// 3) Generate data
	// Ensure FK nullable is correct (from CREATE TABLE col NOT NULL)
	fks = planner.FillFKNullability(schema, fks)

	cfg := planner.DataGenConfig{
		DefaultRows:        *rows,
		RequestedRows:      map[string]int{},
		NullableFKNullRate: *nullRate,
		Seed:               *seed,
	}

	// If --table is set: only that table count is fixed and dependencies get propagated.
	// If empty: generator will create DefaultRows for all tables.
	if *table != "" {
		cfg.RequestedRows[*table] = *rows
	} else {
		// empty RequestedRows means: generate DefaultRows for all
		cfg.RequestedRows = map[string]int{}
	}

	data, err := planner.GenerateRandomData(schema, plan, fks, cfg)
	if err != nil {
		panic(err)
	}

	sql := planner.RenderInserts(schema, plan, data)

	// 4) Save
	if err := os.WriteFile(*outPath, []byte(sql), 0644); err != nil {
		panic(err)
	}

	fmt.Println("\nGenerated data saved to:", *outPath)

	// Optional quick stats: how many rows per table
	fmt.Println("\nGenerated rows per table:")
	for _, t := range plan.InsertOrder {
		if rs := data.Rows[t]; len(rs) > 0 {
			fmt.Printf(" - %s: %d\n", t, len(rs))
		}
	}
}

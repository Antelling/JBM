includet("src/structs.jl") #types and identity function
includet("src/analyze_population.jl") #function operating only on a population
includet("src/analyze_solution.jl") #determine solution properties
includet("src/analyze_problem.jl") #determine problem properties
includet("src/load_datasets.jl") #parse beasely benchmark problems
includet("src/initial_population.jl") #generate an initial population
includet("src/S_metaheuristics.jl") #S metaheuristics
includet("src/P_perturbs.jl") #transformations for P metaheuristics
includet("src/P_meta_coord.jl") #apply transformations of P-metas
includet("src/common_metaheuristics.jl") #definitions of common metaheuristics

problems = parse_file("./benchmark_problems/mdmkp_ct1.txt")
problem = problems[1]
pop = greedy_construct(problem, 3, ls=make_solution, max_time=10)
sol = pop[1]

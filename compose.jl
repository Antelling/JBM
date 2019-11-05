include("src/structs.jl") #types and identity function
include("src/analyze_population.jl") #function operating only on a population
include("src/analyze_solution.jl") #determine solution properties
include("src/analyze_problem.jl") 
include("src/load_datasets.jl") #parse beasely benchmark problems
include("src/initial_population.jl") #generate an initial population
include("src/S_metaheuristics.jl") #S metaheuristics
include("src/P_perturbs.jl") #transformations for P metaheuristics
include("src/P_meta_coord.jl") #apply transformations of P-metas

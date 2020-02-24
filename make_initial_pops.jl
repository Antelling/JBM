using JSON
include("compose.jl")

function dense_rep(bitarray)
	[bit ? 1 : 0 for bit in bitarray]
end

popsize = 60
for dataset in 1:9
    problems = parse_file("./benchmark_problems/mdmkp_ct$(dataset).txt", dataset)
	pops = Vector{Tuple{Problem_ID, Vector{Tuple{Int, Vector{Int}}}}}()
    for (i, problem) in enumerate(problems)
        # generate an initial population using the greedy construct strategy
        # do not force feasibility
        pop::Population = greedy_construct(problem, popsize, ls=NLS, force_valid=false)
		push!(pops, tuple(problem.id, [tuple(sol.score, dense_rep(sol.bitlist)) for sol in pop]))
	end
	file = open("initial_pops/ds$(dataset)_ps$(popsize).json", "w")
	write(file, JSON.json(pops))
	close(file)
end

function test()
	for dataset in [2]
	    problems = parse_file("../benchmark_problems/mdmkp_ct$(dataset).txt")

	    for problem in problems
	        swarm = greedy_construct(problem, 30, ls=make_solution, max_time=10)
		end
	end
end
test()
println("initial pop tests passed")

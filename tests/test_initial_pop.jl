function test_all_feasible()
	for dataset in [2]
	    problems = parse_file("../benchmark_problems/mdmkp_ct$(dataset).txt")

	    for problem in problems
	        pop = greedy_construct(problem, 30, ls=make_solution, max_time=10)
			assure_unique(pop)
		end
	end
end

function test_some_infeasible()
	for dataset in [7]
	    problems = parse_file("../benchmark_problems/mdmkp_ct$(dataset).txt")

	    for problem in problems
	        pop = greedy_construct(problem, 30, ls=make_solution, max_time=1, force_valid=false)
			assure_unique(pop)
		end
	end
end

test_all_feasible()
test_some_infeasible()
println("initial pop tests passed")

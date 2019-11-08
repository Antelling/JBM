function greedy_test_all_feasible()
	for dataset in [2]
	    problems = parse_file("../benchmark_problems/mdmkp_ct$(dataset).txt")

	    for problem in problems[1:20]
	        pop = greedy_construct(problem, 3, ls=make_solution, max_time=10)
			assure_unique(pop)
		end
	end
end

function greedy_test_some_infeasible()
	for dataset in [7]
	    problems = parse_file("../benchmark_problems/mdmkp_ct$(dataset).txt")

	    for problem in problems[1:20]
	        pop = greedy_construct(problem, 30, ls=make_solution, max_time=1, force_valid=false)
			assure_unique(pop)
		end
	end
end

function random_test_all_feasible()
	for dataset in [4]
	    problems = parse_file("../benchmark_problems/mdmkp_ct$(dataset).txt")

	    for problem in problems[1:20]
	        pop = random_init(problem, 3, ls=VND, max_time=10)
			assure_unique(pop)
		end
	end
end

function random_test_some_infeasible()
	for dataset in [9]
	    problems = parse_file("../benchmark_problems/mdmkp_ct$(dataset).txt")

	    for problem in problems[1:20]
	        pop = random_init(problem, 30, ls=make_solution, max_time=1, force_valid=false)
			assure_unique(pop)
		end
	end
end

printstyled("testing initial pop methods...\n",color=:blue)
greedy_test_all_feasible()
printstyled("   greedy all feasible passed. \n", color=:light_black)
greedy_test_some_infeasible()
printstyled("   greedy no feas constraint passed. \n", color=:light_black)

random_test_all_feasible()
printstyled("   random init all feasible embedded VND passed. \n", color=:light_black)
random_test_some_infeasible()
printstyled("   random initi no feas constraint passed. \n", color=:light_black)

printstyled("initial pop tests passed. \n", color=:green)

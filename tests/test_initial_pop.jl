function assure_correct_scores(pop::Population, problem::Problem)
	for sol in pop
		@assert "$(make_solution(sol.bitlist, problem))" == "$sol"
	end
end

function assure_all_feasible(pop::Population)
	for sol in pop
		@assert sol.score > 0
	end
end

function test_make_solution_consistency()
	for dataset in [2]
	    problems = parse_file("../benchmark_problems/mdmkp_ct$(dataset).txt")

	    for problem in problems[1:20]
	        pop = greedy_construct(problem, 3, ls=make_solution, max_time=10)
			for sol in pop
				sol2 = make_solution(sol.bitlist, problem)
				@assert "$sol" == "$sol2"
				@assert "$(make_solution(sol2.bitlist, problem))" == "$sol2"
			end
		end
	end
end

function greedy_test_all_feasible()
	for dataset in [2]
	    problems = parse_file("../benchmark_problems/mdmkp_ct$(dataset).txt")

		for search in [make_solution, VND]
		    for problem in problems[1:20]
				ohgodno = "$problem"
		        pop = greedy_construct(problem, 3, ls=search, max_time=10)
				assure_unique(pop)
				assure_correct_scores(pop, problem)
				assure_all_feasible(pop)
				@assert ohgodno == "$problem"
			end
		end
	end
end

function greedy_test_some_infeasible()
	for dataset in [7]
	    problems = parse_file("../benchmark_problems/mdmkp_ct$(dataset).txt")

	    for problem in problems[1:20]
	        pop = greedy_construct(problem, 30, ls=make_solution, max_time=1, force_valid=false)
			assure_unique(pop)
			assure_correct_scores(pop, problem)
		end
	end
end

function random_test_all_feasible()
	for dataset in [4]
	    problems = parse_file("../benchmark_problems/mdmkp_ct$(dataset).txt")

	    for problem in problems[1:5]
	        pop = random_init(problem, 3, ls=make_solution, max_time=10)
			assure_unique(pop)
			assure_correct_scores(pop, problem)
		end
	end
end

function random_test_some_infeasible()
	for dataset in [9]
	    problems = parse_file("../benchmark_problems/mdmkp_ct$(dataset).txt")

	    for problem in problems[1:20]
	        pop = random_init(problem, 30, ls=make_solution, max_time=1, force_valid=false)
			assure_unique(pop)
			assure_correct_scores(pop, problem)
		end
	end
end

printstyled("testing initial pop methods...\n",color=:blue)
test_make_solution_consistency()
printstyled("   make_solution consistency check passed")
greedy_test_all_feasible()
printstyled("   greedy all feasible passed. \n", color=:light_black)
greedy_test_some_infeasible()
printstyled("   greedy no feas constraint passed. \n", color=:light_black)

random_test_all_feasible()
printstyled("   random init all feasible passed. \n", color=:light_black)
random_test_some_infeasible()
printstyled("   random init no feas constraint passed. \n", color=:light_black)

printstyled("initial pop tests passed. \n", color=:green)

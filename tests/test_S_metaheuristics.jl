function assure_always_improves()
	problems = parse_file("../benchmark_problems/mdmkp_ct1.txt")

    for problem in problems[1:20]
        pop = random_init(problem, 1, ls=make_solution, max_time=1, force_valid=false)

		for method in [_individual_flip, _individual_swap, _individual_double_swap]
			println("testing $method")
			solution = deepcopy(pop[1])
			while true
				new_solution = method(solution, problem)
				@assert new_solution.score >= solution.score
				if new_solution.bitlist != solution.bitlist
					solution = new_solution
				else
					break
				end
			end
		end
	end
end

function test_relative_performance()
    problems = parse_file("../benchmark_problems/mdmkp_ct1.txt")

    for problem in problems[1:20]
        pop = random_init(problem, 30, ls=make_solution, max_time=1, force_valid=false)

		println("local flip found best score of:        ",
				get_best_solution(local_flip(deepcopy(pop), problem)).score)

		println("local swap found best score of:        ",
				get_best_solution(local_swap(deepcopy(pop), problem)).score)

		println("local double swap found best score of: ",
				get_best_solution(local_double_swap(deepcopy(pop), problem)).score)

		println("VND found best score of:               ",
				get_best_solution(VND(deepcopy(pop), problem)).score)

	end
end

printstyled("testing S-metaheuristics...\n",color=:blue)
assure_always_improves()
printstyled("   assured local search methods always result in an improvement. \n", color=:light_black)
test_relative_performance()
printstyled("   relative performance tested. \n", color=:light_black)
# greedy_test_some_infeasible()
# printstyled("   greedy no feas constraint passed. \n", color=:light_black)
#
# random_test_all_feasible()
# printstyled("   random init all feasible embedded VND passed. \n", color=:light_black)
# random_test_some_infeasible()
# printstyled("   random initi no feas constraint passed. \n", color=:light_black)
#
printstyled("S-metaheuristics tests passed. \n", color=:green)

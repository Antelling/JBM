function test_perturbs()
	problems = parse_file("../benchmark_problems/mdmkp_ct3.txt")
	algs_to_test = return_common_metaheuristics(1, 5)

	for p in 1:20
		problem = problems[p]
		pop::Population = random_init(problem, 90, ls=local_swap, force_valid=false)
		for (name, MH) in algs_to_test
			pop_copy = deepcopy(pop)
			MH(pop_copy, problem)
			println("$name found best score of: ", get_best_solution(pop_copy).score)
		end
		println("")
	end
end

test_perturbs()

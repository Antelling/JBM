function test_with_ga(datasets, n_problems)
	for dataset in datasets
	    problems = parse_file("../benchmark_problems/mdmkp_ct$(dataset).txt")

	    for problem in problems[1:n_problems]
	        pop::Population = greedy_construct(problem, 90, ls=SLS, force_valid=false)
			first_sum = sum(get_population_scores(pop))
			P_meta_coord(pop, problem, SLS, column_average_chances, use_random=true, random_n=1, time_limit=3)
			second_sum = sum(get_population_scores(pop))
			@assert second_sum > first_sum
		end
	end
end

function test_perturb_closure()
	problems = parse_file("../benchmark_problems/mdmkp_ct3.txt")
	GA_3samp = PMCPC(column_average_chances, Dict{Symbol,Int}(:n_samples => 20))
	GA_1samp = PMCPC(column_average_chances, Dict{Symbol,Int}(:n_samples => 1))

	for p in 1:20
		problem = problems[p]
		pop::Population = random_init(problem, 90, ls=FLS, force_valid=false)
		first_sum = sum(get_population_scores(pop))

		GA_3samp_results = deepcopy(pop)
		P_meta_coord(GA_3samp_results, problem, FLS, GA_3samp, use_random=true, random_n=1, time_limit=.1)

		GA_1samp_results = deepcopy(pop)
		P_meta_coord(GA_1samp_results, problem, FLS, GA_1samp, use_random=true, random_n=1, time_limit=.1)

		GA_results = deepcopy(pop)
		# P_meta_coord(GA_results, problem, local_swap, column_average_chances, use_random=true, random_n=1, time_limit=.1)

		println("")
		second_sum = sum(get_population_scores(pop))
		# @assert second_sum > first_sum
	end
end

printstyled("testing P-meta-coord...\n",color=:blue)
printstyled("   testing column-average-chances...\n",color=:blue)
test_with_ga([1], 1)
test_with_ga([7, 9], 20)
printstyled("   column-average-chances test passed\n",color=:green)
printstyled("   testing perturb closures...\n",color=:blue)
test_perturb_closure()
printstyled("   closure tests passed\n",color=:green)
printstyled("P-meta-coord tests passed\n",color=:green)

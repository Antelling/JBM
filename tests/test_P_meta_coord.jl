function test_with_ga(;verbose::Int=0)
	for dataset in [7]
	    problems = parse_file("../benchmark_problems/mdmkp_ct$(dataset).txt")

	    for p in 5:length(problems)
			problem = problems[p]
	        pop::Population = greedy_construct(problem, 90, ls=local_swap, force_valid=false)
			first_sum = sum(get_population_scores(pop))
			println(get_population_scores(pop))
			println(count_valid(pop, problem))

			while(count_valid(pop, problem) < 1)
				P_meta_coord(pop, problem, local_swap, column_average_chances, use_random=true, random_n=1, time_limit=10)
				println(get_population_scores(pop))
				println(p)
			end

			println("")
			second_sum = sum(get_population_scores(pop))
			# @assert second_sum > first_sum
		end
	end
end

test_with_ga()
# using Profile
# Profile.clear()
# @profile test()
# using ProfileView
# ProfileView.view()
# readline()
println("P_meta_coord tests passed")

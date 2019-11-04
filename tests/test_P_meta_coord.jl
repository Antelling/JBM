function test_with_plain_ga(;verbose::Int=0)
	for dataset in [2]
	    problems = parse_file("../benchmark_problems/mdmkp_ct$(dataset).txt")

	    for problem in problems[1:4]
	        pop::Population = greedy_construct(problem, 30, ls=make_solution, max_time=1)
			first_sum = sum(get_population_scores(pop))
			P_meta_coord(pop, problem, make_solution, column_average_chances, use_random=true, random_n=1)
			second_sum = sum(get_population_scores(pop))
			@assert second_sum > first_sum
		end
	end
end

test_with_plain_ga()
# using Profile
# Profile.clear()
# @profile test()
# using ProfileView
# ProfileView.view()
# readline()
println("P_meta_coord tests passed")

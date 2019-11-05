include("compose.jl")

function go()
	for dataset in [7]
	    problems = parse_file("benchmark_problems/mdmkp_ct$(dataset).txt")

	    for p in 1:length(problems)
			problem = problems[p]
	        pop::Population = greedy_construct(problem, 180, ls=VND, force_valid=false)

			while(count_valid(pop, problem) < 1)
				P_meta_coord(pop, problem, VND, column_average_chances, use_random=true, random_n=1, time_limit=1)
			end

			println("$p: $(get_representation(get_best_solution(pop)))")
			second_sum = sum(get_population_scores(pop))
			# @assert second_sum > first_sum
		end
	end
end

go()

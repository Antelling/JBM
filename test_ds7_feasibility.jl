include("compose.jl")

function go()
	for dataset in [7]
	    problems = parse_file("benchmark_problems/mdmkp_ct$(dataset).txt")

	    for p in 1:length(problems)
			problem = problems[p]
	        pop::Population = random_init(problem, 180, ls=VND, force_valid=false)

			attempts = 0
			while(count_valid(pop, problem) == 0)
				P_meta_coord(pop, problem, VND, column_average_chances, use_random=true, random_n=1, time_limit=1)
				attempts += 1
				if attempts % 30 == 0 && count_valid(pop, problem) == 0
					pop = random_init(problem, 180, ls=VND, force_valid=false)
				end
			end

			println("$p: $(get_representation(get_best_solution(pop)))")
			second_sum = sum(get_population_scores(pop))
			# @assert second_sum > first_sum
		end
	end
end

go()

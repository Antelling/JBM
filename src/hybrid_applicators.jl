function cyclical_apply_closure(algorithms; time_limit::Number=10, use_max_fails::Bool=false, max_fails::Int=5)
    return function cyclical_apply(pop::Population, problem::Problem)
        start_time = time()
        best_found_score = -2^63
        if use_max_fails
            for solution in pop
                if solution.score > best_found_score
                    best_found_score = solution.score
                end
            end
        end
        curr_fails = 0
        prev_best_found_score = best_found_score
        while curr_fails < max_fails
            for alg in algorithms
                alg(pop, problem) #apply the alg to the pop, alg must act in place
                if time() - start_time > time_limit
                    return pop
                end
            end
            if use_max_fails
                for solution in pop
                    if solution.score > best_found_score
                        best_found_score = solution.score
                    end
                end
                if best_found_score == prev_best_found_score
                    curr_fails += 1
                else
                    curr_fails = 0
                end
            end
            prev_best_found_score = best_found_score
        end
    end
end

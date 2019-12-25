mutable struct CompleteSolution
    bitlist::BitArray
    _objective_value::Int64
    _infeasibility::Int64
    score::Int64
    _upper_bounds_totals::Vector{Int}
    _lower_bounds_totals::Vector{Int}
end

function CompleteSolution(bitlist::BitArray, problem::Problem)
    upper_bounds_totals = [sum(coeffs .* bitlist) for (coeffs, bound) in problem.upper_bounds]
    lower_bounds_totals = [sum(coeffs .* bitlist) for (coeffs, bound) in problem.lower_bounds]

    infeasibility = sum(
        [upper_bounds_totals[i] > upper_bound ? upper_bounds_totals[i] - upper_bound : 0
        for (i, (constraint_coeffs, upper_bound)) in enumerate(problem.upper_bounds)]
    )
    infeasibility += sum(
        [lower_bounds_totals[i] < lower_bound ? lower_bound - lower_bounds_totals[i] : 0
        for (i, (contraint_coeffs, lower_bound)) in enumerate(problem.lower_bounds)]
    )

    objective_value = sum(problem.objective .* bitlist)
    score = infeasibility > 0 ? -infeasibility : objective_value

    return CompleteSolution(
        bitlist,
        objective_value,
        infeasibility,
        score,
        upper_bounds_totals,
        lower_bounds_totals
    )
end

function Solution(sol::CompleteSolution)
    return Solution(sol.bitlist, sol.score)
end

"""Returns true if bit was flipped, false if solution is the same."""
function flip_bit!(solution::CompleteSolution, problem::Problem, bit_index::Int; feas::Bool=false)::Bool
    plus_or_minus = solution.bitlist[bit_index] ? -1 : 1 #if the bit is on, we need to subtract
    updated_objective = solution._objective_value + (plus_or_minus * problem.objective[bit_index])
    if feas && updated_objective < solution._objective_value
        #since we know the solution is starting out feasible, if the objective
        #function decreases, we aren't interested in flipping this bit
        return false
    end
    solution._objective_value = updated_objective

    solution._upper_bounds_totals .+= [plus_or_minus * coeffs[bit_index] for (coeffs, bound) in problem.upper_bounds]
    solution._lower_bounds_totals .+= [plus_or_minus * coeffs[bit_index] for (coeffs, bound) in problem.lower_bounds]

    solution._infeasibility = sum(
        [solution._upper_bounds_totals[i] > upper_bound ? solution._upper_bounds_totals[i] - upper_bound : 0
        for (i, (contraint_coeffs, upper_bound)) in enumerate(problem.upper_bounds)]
    )
    solution._infeasibility += sum(
        [solution._lower_bounds_totals[i] < lower_bound ? lower_bound - solution._lower_bounds_totals[i] : 0
        for (i, (contraint_coeffs, lower_bound)) in enumerate(problem.lower_bounds)]
    )

    solution.score = solution._infeasibility > 0 ? -solution._infeasibility : solution._objective_value
    solution.bitlist[bit_index] = !solution.bitlist[bit_index]

    return true
end

function flip_bit(solution::CompleteSolution, problem::Problem, bit_index::Int)
    solution = deepcopy(solution)
    flip_bit!(solution, problem, bit_index)
    return solution
end

function fast_greedy_flip(sol::Solution, problem::Problem)
    best_sol = CompleteSolution(sol.bitlist, problem)
    improved = true
    while improved
        improved = false
        current_sol = deepcopy(best_sol)
        feas = current_sol.score > 0
        for i in 1:length(current_sol.bitlist)
            #flip bit returns true if the bit was flipped
            if flip_bit!(current_sol, problem, i, feas=feas)
                if current_sol.score > best_sol.score
                    best_sol = deepcopy(current_sol)
                    improved = true
                end
                flip_bit!(current_sol, problem, i) #flip the bit back
            end
        end
    end
    return Solution(best_sol)
end

function greedy_flip(sol::Solution, problem::Problem)
    best_sol = CompleteSolution(sol.bitlist, problem)
    improved = true
    while improved
        improved = false
        current_sol = deepcopy(best_sol)
        for i in 1:length(current_sol.bitlist)
            flip_bit!(current_sol, problem, i)
            if current_sol.score > best_sol.score
                best_sol = deepcopy(current_sol)
                improved = true
            end
            flip_bit!(current_sol, problem, i) #flip the bit back
        end
    end
    return Solution(best_sol)
end

function greedy_flip2(sol::Solution, problem::Problem)
    sol = CompleteSolution(sol.bitlist, problem)
    improved = true
    while improved
        improved = greedy_flip_internal!(sol, problem)
    end
    Solution(sol)
end

function greedy_flip_internal!(sol::CompleteSolution, problem::Problem)::Bool
    index_to_change = 0
    best_found_score = sol.score
    # println("best found score is $best_found_score")
    feas = best_found_score > 0
    # println("feas is $feas")
    for i in 1:length(sol.bitlist)
        # println("starting score is $(sol.score)")
        if flip_bit!(sol, problem, i, feas=feas)
            # println("resulting flip scores $(sol.score)")
            if sol.score > best_found_score
                # println("new high found")
                best_found_score = sol.score
                index_to_change = i
            else
                # println("feas short circuit")
            end

            flip_bit!(sol, problem, i) #flip the bit back
        end
        # println("ending score is $(sol.score)")
    end
    if index_to_change > 0
        # println("changing an index $index_to_change")
        flip_bit!(sol, problem, index_to_change)
        # println("score is now $(sol.score)")
        return true
    end
    return false
end

function greedy_swap(sol::Solution, problem::Problem)
    best_sol = CompleteSolution(sol.bitlist, problem)
    improved = true
    while improved
        improved = false
        current_sol = deepcopy(best_sol) #fixme this is unnecessary
        for (i, bit_value) in enumerate(current_sol.bitlist)
            if bit_value
                flip_bit!(current_sol, problem, i)
                for (j, second_bit_value) in enumerate(current_sol.bitlist)
                    if !second_bit_value
                        flip_bit!(current_sol, problem, j)
                        if current_sol.score > best_sol.score
                            best_sol = deepcopy(current_sol)
                            improved = true
                        end
                        flip_bit!(current_sol, problem, j)
                    end
                end
                flip_bit!(current_sol, problem, i)
            end
        end
    end
    return Solution(best_sol)
end

function eager_flip(sol::Solution, problem::Problem)
    complete_sol = CompleteSolution(sol.bitlist, problem)
    best_found_score = complete_sol.score
    improved = true
    while improved
        improved = false
        for i in 1:length(complete_sol.bitlist)
            flip_bit!(complete_sol, problem, i)
            if complete_sol.score > best_found_score
                improved = true
                best_found_score = complete_sol.score
                break
            end
            flip_bit!(complete_sol, problem, i)
        end
    end
    return Solution(complete_sol)
end

function random_eager_flip(sol::Solution, problem::Problem)
    complete_sol = CompleteSolution(sol.bitlist, problem)
    best_found_score = complete_sol.score
    improved = true
    while improved
        improved = false
        for i in randperm(length(complete_sol.bitlist))
            flip_bit!(complete_sol, problem, i)
            if complete_sol.score > best_found_score
                improved = true
                best_found_score = complete_sol.score
                break
            end
            flip_bit!(complete_sol, problem, i)
        end
    end
    return Solution(complete_sol)
end

function eager_swap(sol::Solution, problem::Problem)
    complete_sol = CompleteSolution(sol.bitlist, problem)
    best_found_score = complete_sol.score
    improved = true
    while improved
        improved = false
        for (i, bit_value) in enumerate(complete_sol.bitlist)
            if bit_value
                flip_bit!(complete_sol, problem, i)
                for (j, second_bit_value) in enumerate(complete_sol.bitlist)
                    if !second_bit_value
                        flip_bit!(complete_sol, problem, j)
                        if complete_sol.score > best_found_score
                            best_found_score = complete_sol.score
                            improved = true
                            break
                        end
                        flip_bit!(complete_sol, problem, j)
                    end
                end
                if improved
                    break
                end
                flip_bit!(complete_sol, problem, i)
            end
        end
    end
    return Solution(complete_sol)
end

function random_eager_swap(sol::Solution, problem::Problem)
    complete_sol = CompleteSolution(sol.bitlist, problem)
    best_found_score = complete_sol.score
    improved = true
    while improved
        improved = false
        for i in randperm(length(complete_sol.bitlist))
            if complete_sol.bitlist[i]
                flip_bit!(complete_sol, problem, i)
                for j in randperm(length(complete_sol.bitlist))
                    if !complete_sol.bitlist[j]
                        flip_bit!(complete_sol, problem, j)
                        if complete_sol.score > best_found_score
                            best_found_score = complete_sol.score
                            improved = true
                            break
                        end
                        flip_bit!(complete_sol, problem, j)
                    end
                end
                if improved
                    break
                end
                flip_bit!(complete_sol, problem, i)
            end
        end
    end
    return Solution(complete_sol)
end

function greedyflip_then_greedyswap(sol::Solution, problem::Problem)
    sol = greedy_flip(sol, problem)
    return greedy_swap(sol, problem)
end

function eager_VND(sol::Solution, problem::Problem)

end

function VND(sol::Solution, problem::Problem)

end

function control(sol::Solution, problem::Problem)
    sol
end

function test()
    results = Vector{Dict{String,
                Dict{String,Vector{Tuple{Int,Float64}}
                }}}()
    for dataset in [1]
        push!(results, Dict{String,Dict{String,Vector{Tuple{Int,Int}}}}())
        # results[dataset]["bad_random_start"] = Dict{String,Vector{Tuple{Int,Float64}}}()
        # results[dataset]["good_random_start"] = Dict{String,Vector{Tuple{Int,Float64}}}()
        # results[dataset]["optimized_start"] = Dict{String,Vector{Tuple{Int,Float64}}}()

        problems = parse_file("./benchmark_problems/mdmkp_ct4.txt")

        i = 1
        for problem in problems
            println("yeet $i")
            i+=1
            bad_random_start = random_init(problem, 10, force_valid=false)
            good_random_start = random_init(problems[1], 1000, force_valid=false)
            sort!(good_random_start, by=x->x.score)

            optimized_start = deepcopy(good_random_start[1:50])
            GA2 = return_common_metaheuristics(n=1, timelimit=10)["GA2"]
            GA2(optimized_start, problem)
            sort!(optimized_start, by=x->x.score)
            optimized_start = optimized_start[1:10]

            good_random_start = good_random_start[1:10]

            for (pop, popname) in [
                    (optimized_start, "optimized start"),
                    (good_random_start, "good random start"),
                    (bad_random_start, "bad random start")]
                if !(popname in keys(results[dataset]))
                    results[dataset][popname] = Dict{String,Vector{Tuple{Int,Float64}}}()
                end
                for (alg, algname) in [
                        (control, "control"),
                        (greedy_flip, "greedy flip"),
                        (greedy_flip2, "greedy flip2"),
                        (fast_greedy_flip, "fast greedy flip"),
                        # (eager_flip, "eager flip"),
                        # (random_eager_flip, "random eager flip"),
                        # (greedy_swap, "greedy swap"),
                        # (eager_swap, "eager swap"),
                        # (random_eager_swap, "random eager swap"),
                        # (greedyflip_then_greedyswap, "greedy_flip then greedy_swap")
                    ]
                    if !(algname in keys(results[dataset][popname]))
                        results[dataset][popname][algname] = Vector{Tuple{Int,Float64}}()
                    end
                    for sol in pop
                        start_time = time()
                        score = alg(deepcopy(sol), problem).score
                        end_time = time()
                        push!(results[dataset][popname][algname], (score, end_time - start_time))
                    end
                end
            end
        end
    end
    return results
end

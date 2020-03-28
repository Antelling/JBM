"""evaluates score of bitlist

If the solution is feasible, return the objective function score.
If the solution is infeasible, return the negative infeasibility. """
function score_bitlist(bl::BitArray, problem::Problem)::Int
    total_infeas = 0
    for upper_bound in problem.upper_bounds
        diff = sum(upper_bound[1] .* bl) - upper_bound[2]
        if diff > 0
            total_infeas += diff
        end
    end
    for lower_bound in problem.lower_bounds
        diff = lower_bound[2] - sum(lower_bound[1] .* bl)
        if diff > 0
            total_infeas += diff
        end
    end
    if total_infeas > 0
        return -total_infeas
    else
        total = sum(problem.objective .* bl)
        return total
    end
end

"""converts a BitArray into a Solution.
A solution contains the bitlist and the score of the bitlist. This function
uses score_bitlist to calculate the solution. """
function make_solution(bl::BitArray, problem::Problem)
    return Solution(bl, score_bitlist(bl, problem))
end

"""Structure that holds solution and cost matrix for problem,
for fast bit flips."""
mutable struct CompleteSolution
    bitlist::BitArray
    _objective_value::Int64
    _infeasibility::Int64
    score::Int64
    _upper_bounds_totals::Vector{Int}
    _lower_bounds_totals::Vector{Int}
end

"""create a CompleteSolution from a bitlist and problem"""
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

"""Convert a CompleteSolution into a Solution.
Extracts the bitlist and score and forms a new immutable Solution."""
function Solution(sol::CompleteSolution)
    return Solution(sol.bitlist, sol.score)
end

"""Attempts to flip a bit of the passed CompleteSolution.
If a bit flip will improve the score of the solution, flip the bit and return
true. Otherwise, don't do anything and return false."""
function flip_bit!(solution::CompleteSolution, problem::Problem, bit_index::Int;
	feas::Bool=false)::Bool
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

"""Behaves the same as flip_bit!, but makes a deepcopy of the passed
CompleteSolution, and returns the new CompleteSolution instead of a Boolean."""
function flip_bit(solution::CompleteSolution, problem::Problem, bit_index::Int)
    solution = deepcopy(solution)
    flip_bit!(solution, problem, bit_index)
    return solution
end

# ========================= NEIGHBORHOOD SEARCHES ============================ #

"""Performs an exhaustive search of the local bit flip neighborhood, over and
over, until no improvement is found. """
function greedy_flip(sol::Solution, problem::Problem)
    sol = CompleteSolution(sol.bitlist, problem)
    improved = true
    while improved
        improved = greedy_flip_internal!(sol, problem)
    end
    Solution(sol)
end

"""Loop over every bit in a bitarry, and calculate the score if the bit were
flipped. Then, if an improved score were found, flip the bit that lead to the
greatest improvement, and return true. Else, return false. """
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

"""Exhaustive eager search.

For every solution, loop over each bit in a random order. If a bit flipping
will improve the score, immediately flip the bit and restart the search.
Once an improvement fails to be found, return the current solution. """
function eager_flip(sol::Solution, problem::Problem)
    sol = CompleteSolution(sol.bitlist, problem)
    improved = true
    while improved
        improved = eager_flip_internal!(sol, problem)
    end
    Solution(sol)
end

"""Loop over the bits of a solution in a random order. If flipping a bit will
improve the score, flip the bit andd return true. Else, continue the search. If
no improvement is found, return false. """
function eager_flip_internal!(sol::CompleteSolution, problem::Problem)::Bool
    starting_score = sol.score
    feas = starting_score > 0
    for i in randperm(length(sol.bitlist))
        if flip_bit!(sol, problem, i, feas=feas)
            if sol.score > starting_score
                return true
            else
                flip_bit!(sol, problem, i)
            end
        end
    end
    return false
end

"""Like greedy flip, but use the bit swap neighborhood instead."""
function greedy_swap(sol::Solution, problem::Problem)
    sol = CompleteSolution(sol.bitlist, problem)
    improved = true
    while improved
        improved = greedy_swap_internal!(sol, problem)
    end
    Solution(sol)
end

"""Like greedy flip internal, but use the local swap neighborhood. """
function greedy_swap_internal!(sol::CompleteSolution, problem::Problem)::Bool
    removed_index = 0
    inserted_index = 0
    best_found_score = sol.score
    n_dimensions = length(sol.bitlist)
    for i in 1:n_dimensions
        if sol.bitlist[i]
            flip_bit!(sol, problem, i) #no feas check because even if the first
            # flip takes us out of feasibility, the second flip will put us
            # back in
            inner_feas = sol.score > 0
            for j in 1:n_dimensions
                if !sol.bitlist[j]
                    if flip_bit!(sol, problem, j, feas=inner_feas)
                        if sol.score > best_found_score
                            best_found_score = sol.score
                            inserted_index = i
                            removed_index = j
                        end
                        flip_bit!(sol, problem, j)
                    end
                end
            end
            flip_bit!(sol, problem, i)
        end
    end

    if removed_index > 0 # will only be changed if an improvement is found
        flip_bit!(sol, problem, removed_index)
        flip_bit!(sol, problem, inserted_index)
        return true
    end
    return false
end


function eager_swap(sol::Solution, problem::Problem)
    sol = CompleteSolution(sol.bitlist, problem)
    improved = true
    while improved
        improved = greedy_swap_internal!(sol, problem)
    end
    Solution(sol)
end

function eager_swap_internal!(sol::CompleteSolution, problem::Problem)
    best_found_score = sol.score
    n_dimensions = length(sol.bitlist)
    for i in randperm(n_dimensions)
        if sol.bitlist[i]
            flip_bit!(sol, problem, i) #no feas check because even if the first
            # flip takes us out of feasibility, the second flip will put us
            # back in
            inner_feas = sol.score > 0
            for j in randperm(n_dimensions)
                if !sol.bitlist[j]
                    if flip_bit!(sol, problem, j, feas=inner_feas)
                        if sol.score > best_found_score
                            return true
                        end
                        flip_bit!(sol, problem, j)
                    end
                end
            end
            flip_bit!(sol, problem, i)
        end
    end

    return false
end

"""Exhausted flip then exhausted swap"""
function exhflip_then_exhswap(sol::Solution, problem::Problem)
    sol = CompleteSolution(sol.bitlist, problem)
    improved = true
    while improved
        improved = greedy_flip_internal!(sol, problem)
    end
    improved = true
    while improved
        improved = greedy_swap_internal!(sol, problem)
    end
    Solution(sol)
end

"""flip then swap until exhaustion"""
function exh_flip_and_swap(sol::Solution, problem::Problem)
    sol = CompleteSolution(sol.bitlist, problem)
    improved = true
    improved2 = false
    while improved
        improved = greedy_flip_internal!(sol, problem)
        improved2 = greedy_swap_internal!(sol, problem)
        improved = improved || improved2 # I don't know how to shorten this
        # without short circuiting
    end
    Solution(sol)
end

"""flip until exhaustion, then swap and restart"""
function exh_flip_or_swap(sol::Solution, problem::Problem)
    sol = CompleteSolution(sol.bitlist, problem)
    while greedy_flip_internal!(sol, problem) || greedy_swap_internal!(sol, problem)
    end
    Solution(sol)
end

"""flip until exhaustion, then swap and restart"""
function exh_greedyflip_or_eagerswap(sol::CompleteSolution, problem::Problem)
    while greedy_flip_internal!(sol, problem) || eager_swap_internal!(sol, problem)
    end
    Solution(sol)
end

"""Slow Local Swap"""
function SLS(bl::BitArray, problem::Problem)
    #make a dummy Solution with a score of 0, because the bitarray will be taken
    # out to make a CompleteSolution with correct score
    exh_flip_and_swap(Solution(bl, 0), problem)
end

"""Medium Local Swap"""
function MLS(bl::BitArray, problem::Problem)
    #make a dummy Solution with a score of 0, because the bitarray will be taken
    # out to make a CompleteSolution with correct score
    exh_greedyflip_or_eagerswap(CompleteSolution(bl, problem), problem)
end

"""Fast LocaL Swap"""
function FLS(bl::BitArray, problem::Problem)
    #make a dummy Solution with a score of 0, because the bitarray will be taken
    # out to make a CompleteSolution with correct score
    greedy_flip(Solution(bl, 0), problem)
end

"""Repair Operator"""
function repair(bl::BitArray, problem::Problem)
	sol = CompleteSolution(bl, problem)
    improved = true
    while improved && sol.score < 0
        improved = greedy_flip_internal!(sol, problem)
    end
    Solution(sol)
end


"""No Local Search"""
function NLS(bl::BitArray, problem::Problem)
    make_solution(bl, problem)
end

"""Control"""
function control(sol::Solution, problem::Problem)
    sol
end

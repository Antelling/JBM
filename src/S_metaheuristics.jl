"""Apply the local_swap search to every solution in a population"""
function local_swap(pop::Population, problem::Problem)::Population
    for i in 1:length(pop)
        new_sol = local_swap(pop[i], problem)
        if !contains(pop, new_sol)
            pop[i] = new_sol
        end
    end
    return pop
end

"""Apply the local_swap search to a single solution"""
function local_swap(sol::Solution, problem::Problem)::Solution
    prev_sol = sol
    new_sol = _individual_swap(sol, problem)
    while prev_sol.bitlist != new_sol.bitlist
        prev_sol = deepcopy(new_sol)
        new_sol = _individual_swap(new_sol, problem)
    end
    return new_sol
end

"""Apply the local_swap search to a single bitlist"""
function local_swap(bl::BitArray, problem::Problem)::Solution
    return local_swap(make_solution(bl, problem), problem)
end

"""Apply the local_double_swap search to every solution in a population"""
function local_double_swap(pop::Population, problem::Problem)::Population
    for i in 1:length(pop)
        new_sol = local_double_swap(pop[i], problem)
        if !contains(pop, new_sol)
            pop[i] = new_sol
        end
    end
    return pop
end

"""Apply the local_double_swap search to a single solution"""
function local_double_swap(sol::Solution, problem::Problem; only_one_trial::Bool=false)::Solution
    while true
        testing_sol = deepcopy(sol)
        for (i, first_bit_val) in enumerate(testing_sol.bitlist) #loop over every bit in the bitlist
            if first_bit_val #if the bit is on
                testing_sol.bitlist[i] = false
                for (j, second_bit_val) in enumerate(testing_sol.bitlist) #start a second loop over every bit
                    if !second_bit_val #if the second bit is off
                        testing_sol.bitlist[j] = true
                        best_single_swap = _individual_swap(testing_sol, problem)
                        if best_single_swap.score > sol.score
                            sol = best_single_swap
                        end
                        testing_sol.bitlist[j] = false
                    end
                end
                testing_sol.bitlist[i] = true
            end
        end
        if sol.bitlist == testing_sol.bitlist || only_one_trial
            break
        end
    end
    return sol
end

"""Apply the local_double_swap search to a single bitlist"""
function local_double_swap(bl::BitArray, problem::Problem)::Solution
    return local_double_swap(make_solution(bl, problem), problem)
end

"""Return the best solution in the swap neighborhood"""
function _individual_swap(solution::Solution, problem::Problem; only_repair::Bool=false)::Solution
    bl = solution.bitlist
    objective_value = solution.score
    upper_values::Vector{Int} = [sum(bl .* bound[1]) for bound in problem.upper_bounds]
    lower_values::Vector{Int} = [sum(bl .* bound[1]) for bound in problem.lower_bounds]

    best_found_objective = objective_value
    best_found_bitlist::BitArray = bl

    #now we need to determine the infeasibility of this solution
    lowest_found_infeasibility = 0
    for i in 1:length(upper_values)
        diff = upper_values[i] - problem.upper_bounds[i][2]
        if diff > 0
            lowest_found_infeasibility += diff
        end
    end
    for i in 1:length(lower_values)
        diff = problem.lower_bounds[i][2] - lower_values[i]
        if diff > 0
            lowest_found_infeasibility += diff
        end
    end

    for (i, first_bit_val) in enumerate(bl) #loop over every bit in the bitlist
        if first_bit_val #if the bitlist is on
            for (j, second_bit_val) in enumerate(bl) #start a second loop over every bit
                if !second_bit_val #if the second bit is off

                    #first update objective function value:
                    new_objective_value = objective_value - problem.objective[i] + problem.objective[j]

                    if lowest_found_infeasibility == 0 && new_objective_value <= best_found_objective
                        #if we have already found a valid solution, and this
                        #solution is worse than that solution, we are not
                        #interested in continuing
                        continue
                    end

                    #we are going to re-total infeasibility
                    new_infeasibility = 0

                    #now we update all upper bounds
                    for p in 1:length(problem.upper_bounds) #check every upper bound
                        changed_value = upper_values[p] - problem.upper_bounds[p][1][i] + problem.upper_bounds[p][1][j]
                        diff = changed_value - problem.upper_bounds[p][2]
                        if diff > 0
                            new_infeasibility += diff
                            if new_infeasibility > lowest_found_infeasibility #TODO: benchmark this option
                                #we never want to become more infeasible
                                break
                            end
                        end
                    end

                    if lowest_found_infeasibility == 0 && new_infeasibility > 0
                        #we already have a feasible solution, so are not interested
                        #in this infeasible one
                        continue
                    end

                    for p in 1:length(problem.lower_bounds) #check every lower bound
                        changed_value = lower_values[p] - problem.lower_bounds[p][1][i] + problem.lower_bounds[p][1][j]
                        diff = problem.lower_bounds[p][2] - changed_value
                        if diff > 0
                            new_infeasibility += diff
                            if new_infeasibility > lowest_found_infeasibility #TODO: benchmark this option
                                break
                            end
                        end
                    end

                    #now we need to determine if this new solution is better
                    #than our current best
                    #first, we never want to become more infeasible
                    if new_infeasibility > lowest_found_infeasibility
                        break
                    elseif new_infeasibility == lowest_found_infeasibility
                        #if we have an equal infeasibility, choose the solution
                        #with the better objective function
                        if new_objective_value > best_found_objective
                            best_found_objective = new_objective_value
                            best_found_bitlist = deepcopy(bl)
                            best_found_bitlist[i] = false
                            best_found_bitlist[j] = true
                        end
                    else #new_infeasibility < lowest_found_infeasibility
                        best_found_objective = new_objective_value
                        best_found_bitlist = deepcopy(bl)
                        best_found_bitlist[i] = false
                        best_found_bitlist[j] = true
                        lowest_found_infeasibility = new_infeasibility
                    end
                end
            end
        end
    end
    if lowest_found_infeasibility == 0
        score = best_found_objective
    else
        score = -lowest_found_infeasibility
    end
    return Solution(best_found_bitlist, score)
end

"""Apply local flip search to whole population"""
function local_flip(pop::Population, problem::Problem)
    println("local flip for pop called")
    for i in 1:length(pop)
        new_sol = local_flip(pop[i], problem)
        if !contains(pop, new_sol)
            pop[i] = new_sol
        end
    end
    return pop
end

"""Apply local flip search to single solution"""
function local_flip(sol::Solution, problem::Problem)
    println("local flip for sol called")
    prev_sol = sol
    new_sol = _individual_flip(sol, problem)
    while prev_sol.bitlist != new_sol.bitlist
        prev_sol = deepcopy(new_sol)
        new_sol = _individual_flip(new_sol, problem)
    end
    return new_sol
end

"""Apply the local_flip search to a single bitlist"""
function local_flip(bl::BitArray, problem::Problem)::Solution
    return local_flip(make_solution(bl, problem), problem)
end

"""Returns best solution from local flip neighborhood"""
function _individual_flip(sol::Solution, problem::Problem)
    objective_value = sol.score
    bl = sol.bitlist
    upper_values::Vector{Int} = [sum(bl .* bound[1]) for bound in problem.upper_bounds]
    lower_values::Vector{Int} = [sum(bl .* bound[1]) for bound in problem.lower_bounds]

    best_found_objective = objective_value
    best_found_bitlist = bl

    #now we need to determine the infeasibility of this solution
    lowest_found_infeasibility = 0
    for i in 1:length(upper_values)
        diff = upper_values[i] - problem.upper_bounds[i][2]
        if diff > 0
            lowest_found_infeasibility += diff
        end
    end
    for i in 1:length(lower_values)
        diff = problem.lower_bounds[i][2] - lower_values[i]
        if diff > 0
            lowest_found_infeasibility += diff
        end
    end

    println("using $lowest_found_infeasibility, $best_found_objective as seed")

    for i in 1:length(bl)
        on_or_off = bl[i] ? -1 : 1

        new_objective_value = objective_value + (problem.objective[i] * on_or_off)
        if lowest_found_infeasibility == 0 && new_objective_value <= best_found_objective
            continue
        end

        new_infeasibility = 0

        for p in 1:length(problem.upper_bounds)
            changed_value = upper_values[p] + (problem.upper_bounds[p][1][i] * on_or_off)
            diff = changed_value - problem.upper_bounds[p][2]
            if diff > 0
                new_infeasibility += diff
                if new_infeasibility > lowest_found_infeasibility #TODO: benchmark this option
                    #we never want to become more infeasible
                    break
                end
            end
        end

        if lowest_found_infeasibility == 0 && new_infeasibility > 0
            #we already have a feasible solution, so are not interested
            #in this infeasible one
            continue
        end

        for p in 1:length(problem.lower_bounds)
            changed_value = lower_values[p] + (problem.lower_bounds[p][1][i] * on_or_off)
            diff = problem.lower_bounds[p][2] - changed_value
            if diff > 0
                new_infeasibility += diff
                if new_infeasibility > lowest_found_infeasibility #TODO: benchmark this option
                    break
                end
            end
        end

        #now we need to determine if this new solution is better
        #than our current best
        #first, we never want to become more infeasible
        if new_infeasibility > lowest_found_infeasibility
            break
        elseif new_infeasibility == lowest_found_infeasibility
            #if we have an equal infeasibility, choose the solution
            #with the better objective function
            if new_objective_value > best_found_objective
                best_found_objective = new_objective_value
                println("  improvement to $new_infeasibility, $best_found_objective found")
                best_found_bitlist = deepcopy(bl)
                best_found_bitlist[i] = !best_found_bitlist[i]
            end
        else #new_infeasibility < lowest_found_infeasibility
            best_found_objective = new_objective_value
            best_found_bitlist = deepcopy(bl)
            best_found_bitlist[i] = !best_found_bitlist[i]
            lowest_found_infeasibility = new_infeasibility
            println("  improvement to $new_infeasibility, $best_found_objective found")
        end
    end
    return Solution(best_found_bitlist, best_found_objective)
end

function _individual_double_swap(solution::Solution, problem::Problem)
    return local_double_swap(solution, problem, only_one_trial=true)
end

"""Apply VND search to every solution in population"""
function VND(pop::Population, problem::Problem)::Population
    for i in 1:length(pop)
        new_sol = VND(pop[i], problem)
        if !contains(pop, new_sol)
            pop[i] = new_sol
        end
    end

    return pop
end

"""Apply VND search to single solution"""
function VND(sol::Solution, problem::Problem)::Solution
    prev_sol = sol

    option_one = _individual_flip(sol, problem)
    option_two = _individual_swap(sol, problem)
    option_three = local_double_swap(sol, problem, only_one_trial=true)

    println(option_one.score," ", option_two.score," ", option_three.score)

    one_two_max = option_one.score < option_two.score ? option_two : option_one
    new_sol = one_two_max.score < option_three.score ? option_three : one_two_max
    println(new_sol.score)

    while prev_sol.bitlist != new_sol.bitlist
        prev_sol = new_sol
        option_one = _individual_flip(sol, problem)
        option_two = _individual_swap(sol, problem)
        option_three = local_double_swap(sol, problem, only_one_trial=true)

        one_two_max = option_one.score < option_two.score ? option_two : option_one
        new_sol = one_two_max.score < option_three.score ? one_two_max : option_three
    end
    return new_sol
end

"""Apply VND to a single bitlist"""
function VND(bl::BitArray, problem::Problem)::Solution
    return VND(make_solution(bl, problem), problem)
end

"""evaluates score of bitlist"""
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

"""converts a BitArray into a Solution"""
function make_solution(bl::BitArray, problem::Problem)
    return Solution(bl, score_bitlist(bl, problem))
end

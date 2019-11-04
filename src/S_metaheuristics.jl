"""Apply the local_swap search to every solution in a population"""
function local_swap(pop::Population, problem::Problem)::Population
    for i in 1:length(pop)
        new_sol = local_swap(pop[i], problem)
        if !(new_sol in pop)
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
function local_swap(bl::BitList, problem::Problem)::Solution
    return local_swap(make_solution(bl, problem), problem)
end

"""Return the best solution in the swap neighborhood"""
function _individual_swap(solution::Solution, problem::Problem; only_repair::Bool=false)::Solution
    bl = solution.bitlist
    objective_value = solution.score
    upper_values::Vector{Int} = [sum(bl .* bound[1]) for bound in problem.upper_bounds]
    lower_values::Vector{Int} = [sum(bl .* bound[1]) for bound in problem.lower_bounds]

    best_found_objective = objective_value
    best_found_bitlist::BitList = deepcopy(bl)

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

    for i in 1:length(bl) #loop over every bit in the bitlist
        if bl[i] #if the bitlist is on
            for j in 1:length(bl) #start a second loop over every bit
                if !bl[j] #if the second bit is off

                    #first update objective function value:
                    new_objective_value = objective_value - problem.objective[i] + problem.objective[j]

                    #we are going to re-total infeasibility
                    new_infeasibility = 0

                    if lowest_found_infeasibility == 0 && new_objective_value <= best_found_objective
                        #if we have already found a valid solution, and this
                        #solution is worse than that solution, we are not
                        #interested in continuing
                        continue
                    end

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
                        end
                        if new_infeasibility > lowest_found_infeasibility #TODO: benchmark this option
                            break
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
    for i in 1:length(pop)
        new_sol = local_flip(pop[i], problem)
        if !(new_sol in pop)
            pop[i] = new_sol
        end
    end
    return pop
end

"""Apply local flip search to single solution"""
function local_flip(sol::Solution, problem::Problem)
    prev_sol = sol
    new_sol = _individual_flip(sol, problem)
    while prev_sol != new_sol
        prev_sol = deepcopy(new_sol)
        new_sol = _individual_flip(new_sol, problem)
    end
    return new_sol
end

"""Returns best solution from local flip neighborhood"""
function _individual_flip(sol::Solution, problem::Problem)
    objective_value = sol.score
    bl = sol.bitlist
    upper_values::Vector{Int} = [sum(bl .* bound[1]) for bound in problem.upper_bounds]
    lower_values::Vector{Int} = [sum(bl .* bound[1]) for bound in problem.lower_bounds]

    best_found_objective = objective_value
    best_found_bitlist = bl
    for i in 1:length(bl)
        valid = true
        on_or_off = bl[i] ? -1 : 1

        new_objective_value = objective_value + (problem.objective[i] * on_or_off)
        if new_objective_value <= best_found_objective
            continue
        end

        for p in 1:length(problem.upper_bounds)
            changed_value = upper_values[p] + (problem.upper_bounds[p][1][i] * on_or_off)
            if changed_value > problem.upper_bounds[p][2]
                valid = false
                break
            end
        end

        if valid
            for p in 1:length(problem.lower_bounds)
                changed_value = lower_values[p] + (problem.lower_bounds[p][1][i] * on_or_off)
                if changed_value < problem.lower_bounds[p][2]
                    valid = false
                    break
                end
            end
        end

        if valid
            #we know the objective value has improved because we would have quit
            #otherwise
            best_found_objective = new_objective_value
            best_found_bitlist = deepcopy(bl)
            best_found_bitlist[i] = !best_found_bitlist[i]
        end
    end
    return Solution(best_found_bitlist, best_found_objective)
end

"""Apply VND search to every solution in population"""
function VND(pop::Population, problem::Problem)::Population
    for i in 1:length(pop)
        new_sol = VND(pop[i], problem)
        if !(new_sol in pop)
            pop[i] = new_sol
        end
    end

    return pop
end

"""Apply VND search to single solution"""
function VND(sol::Solution, problem::Problem)::Solution
    prev_sol = sol
    new_sol = _individual_flip(sol, problem)
    new_sol = _individual_swap(new_sol, problem)
    while prev_sol != new_sol
        prev_sol = deepcopy(new_sol)
        new_sol = _individual_flip(new_sol, problem)
        new_sol = _individual_swap(new_sol, problem)
    end
    return new_sol
end

"""evaluates score of bitlist"""
function score_bitlist(bl::BitList, problem::Problem)::Int
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
        @assert total > 0
        return total
    end
end

"""converts a BitList into a Solution"""
function make_solution(bl::BitList, problem::Problem)
    return Solution(bl, score_bitlist(bl, problem))
end

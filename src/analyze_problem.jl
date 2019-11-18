"""get inclusive (min, max) tuple of the range sum(BitArray) may return"""
function get_solution_range(p::Problem)
    problem = deepcopy(p) #list comprehension introduces side effects
    max_value = min([get_max_on(bound[1], bound[2]) for bound in problem.upper_bounds]...)
    min_value = max([get_min_on(bound[1], bound[2]) for bound in problem.lower_bounds]...)
    return (min_value, max_value)
end

"""find maximum amount of variables that can be turned on
before the upper bound is violated"""
function get_max_on(weights::Vector{Int}, max_value::Int)
    sort!(weights) #we sort so the smallest comes first
    i = 0
    total = 0
    for weight in weights
        total += weight
        if total > max_value
            break
        end
        i += 1
    end
    return i
end

"""find minimum amount of variables that can be turned on while still
satisfying lower bound"""
function get_min_on(weights::Vector{Int}, min_value::Int)
    sort!(weights, by=i->-i) #sort descending
    i = 0
    total = 0
    for weight in weights
        if total >= min_value
            break
        end
        total += weight
        i += 1
    end
    return i
end

"""Reduce lower bound constraint of problem to floor(.1*bound)"""
function decimate_lowerbounds(problem::Problem)
    new_lower_bounds::Vector{Tuple{Vector{Int},Int}} = []
    for lower_bound in problem.lower_bounds
        push!(new_lower_bounds, Tuple([lower_bound[1], floor(lower_bound[2]/10)]))
    end
    return ProblemInstance(problem.objective, problem.upper_bounds, new_lower_bounds, problem.index)
end

"""determines if the bitlist violates any constraints"""
function is_valid(solution::BitList, problem::Problem)::Bool
    for upper_bound in problem.upper_bounds
        if sum(upper_bound[1] .* solution) > upper_bound[2]
            return false
        end
    end
    for lower_bound in problem.lower_bounds
        if sum(lower_bound[1] .* solution) < lower_bound[2]
            return false
        end
    end
    return true
end

"""determines if the solution violates any constraints"""
function is_valid(solution::Solution, problem::Problem)
    return is_valid(solution.bitlist, problem)
end

"""Serialize solution into string"""
function get_representation(solution::Solution)
    bl_rep = join([a ? "0" : "1" for a in solution.bitlist], ",")
    return "Solution([$bl_rep], $(solution.score))"
end

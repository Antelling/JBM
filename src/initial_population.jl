using Random: randperm

"""Generate a permutation of items to put in the knapsack. Go through the
permutation and add items if they don't violate any dimension constraints.
Check if it is valid. Then, using the same permuation, loop through and remove
items as long as it wouldn't violate any demand constraints. """
function greedy_construct(problem::Problem, n_solutions::Int=50; ls::Function=VND,
            max_time::Int=60)::Population
    n_dimensions = length(problem.objective)

    valid_solutions = Set{Solution}()
    start_time = time()
    while length(valid_solutions) < n_solutions && (time() - start_time) < max_time

        order = randperm(n_dimensions)

        bl::BitList = zeros(Int, n_dimensions)
        dimensions = zeros(Int, length(problem.upper_bounds))
        for i in order
            valid = true
            for (j, bound) in enumerate(problem.upper_bounds)
                if dimensions[j] + bound[1][i] > bound[2]
                    valid = false
                    break
                end
            end
            if valid
                for (j, bound) in enumerate(problem.upper_bounds)
                    dimensions[j] += bound[1][i]
                end
                bl[i] = true
            end
        end
        #we have now generated a bitlist, and we know the dimension constraints
        #are all satisfied
        #we will now pass this bitlist to the search function, that will use
        #some strategy to improve it's score. This is slightly inefficient,
        #as we are not passing the knowledge that the dimension constraints
        #are satisfied to the ls function. However, this code is so much shorter
        #I don't care.
        sol::Solution = ls(bl, problem)
        if sol.score > 0 #if it is infeasible, it has a negative objective value
            push!(valid_solutions, sol)
        end

        if length(valid_solutions) == n_solutions
            break
        end

        demand_solution::BitList = ones(Int, n_dimensions)
        dimensions = [sum(bound[1]) for bound in problem.lower_bounds]
        for i in order
            valid = true
            for (j, bound) in enumerate(problem.lower_bounds)
                if dimensions[j] - bound[1][i] < bound[2]
                    valid = false
                    break
                end
            end
            if valid
                for (j, bound) in enumerate(problem.lower_bounds)
                    dimensions[j] -= bound[1][i]
                end
                demand_solution[i] = false
            end
        end
        sol = ls(bl, problem)
        if sol.score > 0 #if it is infeasible, it has a negative objective value
            push!(valid_solutions, sol)
        end
    end
    return collect(valid_solutions)
end

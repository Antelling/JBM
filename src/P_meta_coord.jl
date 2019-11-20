function P_meta_coord(
        population::Population,
        problem::Problem,
        ls::Function,
        perturb::Function;
        use_top::Bool=false, use_bottom::Bool=false, use_mean::Bool=false, use_random::Bool=false,
        top_n::Int=1, bottom_n::Int=1, random_n::Int=1,
        time_limit::Number=10)
    n_dimensions = length(population[1].bitlist)
    #there are a lot of operations where we need to get the top or bottom n
    #which will be fastest if we sort the array
    #however, if we don't need those, we don't need to sort
    if use_top || use_bottom
        sort!(population, by=x->x.score)
    end

    empty_sol = Solution([], 0)

    start_time = time()
    while time() - start_time < time_limit

        #initialize every option to be empty
        #these might be filled with values later, depending on the use_**** booleans
        top_sol = deepcopy(empty_sol)
        bottom_sol = deepcopy(empty_sol)
        random_indices::Vector{Int} = []
        random_sols::Population = []
        mean_of_sols::Vector{Float64} = zeros(n_dimensions)

        #the mean is expensive to calculate and will not change very much, so we
        #calculate it once per iteration
        if use_mean
            for p in population
                mean_of_sols .+= p.bitlist
            end
            mean_of_sols ./= n_dimensions
        end

        for sol_i in 1:length(population)
            sol = population[sol_i]

            #everything else will be reselected every time, for more diversity
            if use_top
                top_sol = rand(population[1:top_n])
            end
            if use_bottom
                bottom_sol = rand(population[end-bottom_n:end])
            end
            if use_random
                random_indices = rand(1:length(population), random_n)
                random_sols = [population[i] for i in random_indices]
            end

            #apply the perturb to generate a new bitlist
            new_bitlist::BitArray = perturb(sol, top_sol=top_sol, bottom_sol=bottom_sol, random_sols=random_sols, mean_of_sols=mean_of_sols)

            #apply the local search
            new_sol::Solution = ls(new_bitlist, problem)

            #pick out the lowest scoring solution from sol_i and random_indices
            lowest_found_index = sol_i
            if use_random
                lowest_found_score = sol.score
                for i in random_indices
                    if population[i].score < lowest_found_score
                        lowest_found_score = population[i].score
                        lowest_found_index = i
                    end
                end
            end

            #check if the new solution is better than the lowest of the parent solutions
            if new_sol.score > population[lowest_found_index].score && !contains(population, new_sol)
                population[lowest_found_index] = new_sol
            end

            #it is now possible that the population is no longer sorted in the correct order
            #however, it probably won't make a difference yet
        end

        #here is where we sort the population again
        if use_top || use_bottom
            sort!(population, by=x->x.score, alg=InsertionSort) #it is nearly sorted so insertion is best
        end
    end
end


"""P-meta-coord-perturb-closure:
Accepts a perturb function and dict of keyword arguments to be applied to the
perturb function when it is called. Returns a function compliant with the
perturb function signature with keyword arguments set.
"""
function PMCPC(perturb::Function, args::Dict{Symbol,Int})
    return function PMCPC_internal(
            first_sol::Solution;
            random_sols::Population,
            top_sol::Solution,
            bottom_sol::Solution,
            mean_of_sols::Vector{Float64}=0)
        return perturb(first_sol;
            random_sols=random_sols,
            top_sol=top_sol,
            bottom_sol=bottom_sol,
            mean_of_sols=mean_of_sols,
            args...)
    end
end


"""P-meta-coord-closure"""
function PMCC(;
    ls::Function,
    perturb::Function,
    use_top::Bool=false,
    use_bottom::Bool=false,
    use_mean::Bool=false,
    use_random::Bool=false,
    top_n::Int=1,
    bottom_n::Int=1,
    random_n::Int=1,
    time_limit::Number=10)

    return function PMCC_internal(pop::Population, problem::Problem)
        return P_meta_coord(pop, problem,
                ls,
                perturb,
                use_top=use_top,
                use_bottom=use_bottom,
                use_mean=use_mean,
                use_random=use_random,
                top_n=top_n,
                bottom_n=bottom_n,
                random_n=random_n,
                time_limit=time_limit)
    end
end

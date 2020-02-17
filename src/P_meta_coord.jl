using StatsBase: sample


function P_meta_coord(
        population::Population,
        problem::Problem,
        ls::Function,
        perturb::Function;
        use_top::Bool=false, use_bottom::Bool=false, use_mean::Bool=false, use_random::Bool=false,
        top_n::Int=1, bottom_n::Int=1, random_n::Int=1,
		update_extreme_solutions_during_iter::Bool=false,
        time_limit::Number=10,
        max_iter::Int=99999999,
        use_max_fails::Bool=false,
        max_fails::Int=5)
    n_dimensions = length(population[1].bitlist)
	popsize = length(population)
    best_found_score = -2^63 #this will be filled in later, if we need it

	#find the starting best score
    #if we need to select the top n or bottom n, we need to sort the array
	#so we can sort here then just take the end
    #however, if we don't need those, we should just do a linear search
    if use_top || use_bottom
        sort!(population, by=x->x.score)
        best_found_score = population[end].score
    else
        for solution in population
            if solution.score > best_found_score
                best_found_score = solution.score
            end
        end
    end

	#variables to keep track of stopping conditions
    start_time = time()
    curr_iters = 0
    num_fails = 0
    prev_best_found_score = best_found_score
	improvement_gens = Vector{Tuple{Int,Int}}()

	#make sure the optional parameters have a fallback
	top_sol_view = view([0], 1)
	bottom_sol_view = view([0], 1)
	#put the starting generation into impgens:
	push!(improvement_gens, tuple(0, best_found_score))
																#ITERATION LOOP:
    while time() - start_time < time_limit && #time constraint
            curr_iters < max_iter #max iterations constraint
        curr_iters += 1
		if use_max_fails && num_fails < max_fails #n failed attempts constraint
			break
		end

        #initialize every option to be empty
        #these might be filled with values later, depending on the use_**** booleans
        random_sols_views = []
        mean_of_sols::Vector{Float64} = zeros(n_dimensions)

        #the mean is expensive to calculate and will not change very much, so we
        #calculate it once per iteration
        if use_mean
            for p in population
                mean_of_sols .+= p.bitlist
            end
            mean_of_sols ./= n_dimensions
        end

		#the top and bottom solutions can be selected either per iteration,
		#or per perturbations
		if !update_extreme_solutions_during_iter
			if use_top
				top_sol_view = view(population, rand(1:top_n))
			end
			if use_bottom
				bottom_sol_view = view(population, rand(popsize-bottom_n:popsize))
			end
		end

        for sol_i in 1:length(population)						#SOLUTION LOOP:
            sol_v = view(population, sol_i) #we use views, to avoid having to make
			# deep copies

			#potentially select top and bottom solution views
			if update_extreme_solutions_during_iter
				if use_top
					top_sol_view = view(population, rand(1:top_n))
				end
				if use_bottom
					bottom_sol_view = view(population, rand(popsize-bottom_n:popsize))
				end
			end
            if use_random
				random_indices = sample(1:length(population), random_n, replace=false)
                random_sols_views = [view(population, i) for i in random_indices]
            end

            #apply the perturb to generate a new bitlist
            new_bitlist::BitArray = perturb(sol_v, top_sol_view=top_sol_view, bottom_sol_view=bottom_sol_view, random_sols_views=random_sols_views, mean_of_sols=mean_of_sols)

            #apply the local search
            new_sol::Solution = ls(new_bitlist, problem)

            #pick out the lowest scoring solution from sol_i and random_indices
            lowest_found_index = sol_i
            if use_random
                lowest_found_score = sol_v[1].score
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

        #sort again if we need to select top or bottom for the next iteration
        if use_top || use_bottom
            sort!(population, by=x->x.score, alg=InsertionSort) #it is nearly sorted so insertion is best
            best_found_score = population[end].score
        else
            for solution in population
                if solution.score > best_found_score
                    best_found_score = solution.score
                end
            end
        end

        if best_found_score == prev_best_found_score
            num_fails += 1
        else
            num_fails = 0
			push!(improvement_gens, tuple(curr_iters, best_found_score))
        end
        prev_best_found_score = best_found_score
    end

	return improvement_gens
end


"""P-meta-coord-perturb-closure:
Accepts a perturb function and dict of keyword arguments to be applied to the
perturb function when it is called. Returns a function compliant with the
perturb function signature with keyword arguments set.
"""
function PMCPC(perturb::Function, args::Dict{Symbol,Float64})
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
    time_limit::Number=10,
    max_iter::Int=999999,
    use_max_fails::Bool=false,
    max_fails::Int=5,
	update_extreme_solutions_during_iter=true)

    return function PMCC_internal(pop::Population, problem::Problem)
        return P_meta_coord(pop, problem, ls, perturb,
                use_top=use_top,
                use_bottom=use_bottom,
                use_mean=use_mean,
                use_random=use_random,
                top_n=top_n,
                bottom_n=bottom_n,
                random_n=random_n,
                time_limit=time_limit,
                max_iter=max_iter,
                use_max_fails=use_max_fails,
                max_fails=max_fails,
				update_extreme_solutions_during_iter=update_extreme_solutions_during_iter)
    end
end

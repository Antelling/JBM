function generate_rao1_narrow_survey(; popsize::Int=30, time_limit::Number=15)
    configurations = Vector{Tuple{String,Any}}()
    push!(configurations, tuple("control", pmeta_control))
    for (search_name, search) in [("fast local search", FLS), ("no local search", make_solution)]
		title = "Rao1 top1 bottom1 " * search_name
		alg = return_common_metaheuristics(n=1, time_limit=time_limit, ls=search, update_extreme_solutions_during_iter=false)["Rao1"]
		push!(configurations, tuple(title, alg))
        for n in [Int(popsize/6), Int(popsize/2)]
			for update_extreme_solutions_during_iter in [true, false]
				suffix = update_extreme_solutions_during_iter ? "perturb" : "iteration"
	            title = "Rao1 top$n bottom$n minmax every $suffix $search_name"
	            alg = return_common_metaheuristics(n=n, time_limit=time_limit, ls=search, update_extreme_solutions_during_iter=true)["Rao1"]
	            push!(configurations, tuple(title, alg))
			end
        end
    end
    configurations
end

function generate_rao2_narrow_survey(; popsize::Int=30, time_limit::Number=15)
	configurations = Vector{Tuple{String,Any}}()
    push!(configurations, tuple("control", pmeta_control))
    for (search_name, search) in [("fast local search", FLS), ("no local search", make_solution)]
		title = "Rao2 top1 bottom1 " * search_name
		alg = return_common_metaheuristics(n=1, time_limit=time_limit, ls=search, update_extreme_solutions_during_iter=false)["Rao2"]
		push!(configurations, tuple(title, alg))
        for n in [Int(popsize/6), Int(popsize/2)]
			for update_extreme_solutions_during_iter in [true, false]
				suffix = update_extreme_solutions_during_iter ? "perturb" : "iteration"
				title = "Rao2 top$n bottom$n minmax every $suffix $search_name"
	            alg = return_common_metaheuristics(n=n, time_limit=time_limit, ls=search)["Rao2"]
	            push!(configurations, tuple(title, alg))
			end
        end
    end
    configurations
end

function generate_jaya_narrow_survey(; popsize::Int=30, time_limit::Number=15)
    configurations = Vector{Tuple{String,Any}}()
    push!(configurations, tuple("control", pmeta_control))
    for (search_name, search) in [("fast local search", FLS), ("no local search", make_solution)]
		title = "Jaya top1 bottom1 " * search_name
		alg = return_common_metaheuristics(n=1, time_limit=time_limit, ls=search, update_extreme_solutions_during_iter=false)["Jaya"]
		push!(configurations, tuple(title, alg))
        for n in [Int(popsize/6), Int(popsize/2)]
			for update_extreme_solutions_during_iter in [true, false]
				suffix = update_extreme_solutions_during_iter ? "perturb" : "iteration"
	            title = "Jaya top$n bottom$n minmax every $suffix $search_name"
	            alg = return_common_metaheuristics(n=n, time_limit=time_limit, ls=search)["Jaya"]
	            push!(configurations, tuple(title, alg))
			end
        end
    end
    configurations
end

function generate_CAC_narrow_survey(; popsize::Int=30, time_limit::Number=15)
    configurations = Vector{Tuple{String,Any}}()
	push!(configurations, tuple("control", pmeta_control))
    for (search_name, search) in [("fast local search", FLS), ("no local search", make_solution)]
        for n in [1, Int(popsize/6)-1, Int(popsize/2)-1]
            title = "CAC $(n+1) parents " * search_name
            alg = return_common_metaheuristics(n=n, time_limit=time_limit, ls=search)["CAC"]
            push!(configurations, tuple(title, alg))
        end
    end
    configurations
end

function generate_TBO_narrow_survey(; popsize::Int=30, time_limit::Number=15)
	configurations = Vector{Tuple{String,Any}}()
    push!(configurations, tuple("control", pmeta_control))
    for (search_name, search) in [("fast local search", FLS), ("no local search", make_solution)]
		title = "TBO top1 " * search_name
		alg = return_common_metaheuristics(n=1, time_limit=time_limit, ls=search, update_extreme_solutions_during_iter=false)["TBO"]
		push!(configurations, tuple(title, alg))
        for n in [Int(popsize/6), Int(popsize/2)]
			for update_extreme_solutions_during_iter in [true, false]
				suffix = update_extreme_solutions_during_iter ? "perturb" : "iteration"
	            title = "TBO top$n minmax every $suffix $search_name"
	            alg = return_common_metaheuristics(n=n, time_limit=time_limit, ls=search)["TBO"]
	            push!(configurations, tuple(title, alg))
			end
        end
    end
	configurations
end


"""LBO and GANM both have only two permutations, instead of six"""
function generate_LBO_narrow_survey(; popsize::Int=30, time_limit::Number=15)
    configurations = Vector{Tuple{String,Any}}()
	push!(configurations, tuple("control", pmeta_control))
    for (search_name, search) in [("fast local search", FLS), ("no local search", make_solution)]
        title = "LBO " * search_name
        alg = return_common_metaheuristics(n=1, time_limit=time_limit, ls=search)["LBO"]
        push!(configurations, tuple(title, alg))
    end
    configurations
end

function generate_GANM_narrow_survey(; popsize::Int=30, time_limit::Number=15)
    configurations = Vector{Tuple{String,Any}}()
	push!(configurations, tuple("control", pmeta_control))
    for (search_name, search) in [("fast local search", FLS), ("no local search", make_solution)]
        title = "GANM " * search_name
        alg = return_common_metaheuristics(n=1, time_limit=time_limit, ls=search)["GANM"]
        push!(configurations, tuple(title, alg))
    end
    configurations
end


"""Because LBO doesn't accept the n argument, TLBO still only has three n args
to test."""
function generate_TLBO_narrow_survey(; popsize::Int=30, time_limit::Number=15)
	configurations = Vector{Tuple{String,Any}}()
    push!(configurations, tuple("control", pmeta_control))
    for (search_name, search) in [("fast local search", FLS), ("no local search", make_solution)]
		title = "TLBO top1 " * search_name
		alg = return_common_metaheuristics(n=1, time_limit=time_limit, ls=search, update_extreme_solutions_during_iter=false)["TBO"]
		push!(configurations, tuple(title, alg))
        for n in [Int(popsize/6), Int(popsize/2)]
			for update_extreme_solutions_during_iter in [true, false]
				suffix = update_extreme_solutions_during_iter ? "perturb" : "iteration"
	            title = "TLBO top$n minmax every $suffix $search_name"
	            alg = return_common_metaheuristics(n=n, time_limit=time_limit, ls=search)["TLBO"]
	            push!(configurations, tuple(title, alg))
			end
        end
    end
	configurations
end

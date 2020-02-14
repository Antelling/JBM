using JSON
include("compose.jl")

function generate_rao1_narrow_survey(; popsize::Int=30, time_limit::Int=15)
    configurations = Vector{Tuple{String,Any}}()
    push!(configurations, tuple("control", pmeta_control))
    for (search_name, search) in [("fast local search", FLS), ("no local search", make_solution)]
        for n in [1, 5, Int(popsize/2)]
            title = "Rao1 top$n bottom$n " * search_name
            alg = return_common_metaheuristics(n=n, time_limit=time_limit, ls=search)["Rao1"]
            push!(configurations, tuple(title, alg))
        end
    end
    configurations
end

function generate_jaya_narrow_survey(; popsize::Int=30, time_limit::Int=15)
    configurations = Vector{Tuple{String,Any}}()
    push!(configurations, tuple("control", pmeta_control))
    for (search_name, search) in [("fast local search", FLS), ("no local search", make_solution)]
        for n in [1, 5, Int(popsize/2)]
            title = "Jaya top$n bottom$n " * search_name
            alg = return_common_metaheuristics(n=n, time_limit=time_limit, ls=search)["Jaya"]
            push!(configurations, tuple(title, alg))
        end
    end
    configurations
end

function generate_CAC_narrow_survey(; popsize::Int=30, time_limit::Int=15)
    configurations = Vector{Tuple{String,Any}}()
    for (search_name, search) in [("fast local search", FLS), ("no local search", make_solution)]
        for n in [1, 4, Int(popsize/2)-1]
            title = "CAC $(n+1) parents " * search_name
            alg = return_common_metaheuristics(n=n, time_limit=time_limit, ls=search)["CAC"]
            push!(configurations, tuple(title, alg))
        end
    end
    configurations
end

function main(; time_limit::Number=10, popsize::Int=30, generator::Function, experiment_name::String, datasets=1:9)
    run(`mkdir -p results/$(experiment_name)`)
    metaheuristics = generator(popsize=popsize, time_limit=time_limit)

    for dataset in datasets 
        problems = parse_file("./benchmark_problems/mdmkp_ct$(dataset).txt", dataset)

        results = Dict{String,Vector}()
		improved_gen_results = Vector{Tuple{Problem_ID, Vector{Tuple{Int,Int}}, String, Float64}}()
        for (name, alg) in metaheuristics
            results[name] = Vector()
        end

        for (i, problem) in enumerate(problems)
            println("")
            println("")
            println("Testing $(problem.id)")

            # generate an initial population using the greedy construct strategy
            # do not force feasibility
            pop::Population = greedy_construct(problem, popsize, ls=NLS, force_valid=false)

            for (name, meta) in metaheuristics
                curr_pop = deepcopy(pop)
                start_time = time()
                improvement_gens = meta(curr_pop, problem)
                end_time = time()
				elapsed_time = end_time - start_time
				push!(improved_gen_results, tuple(problem.id, improvement_gens, name, elapsed_time))
                highest = get_population_scores(curr_pop)[end]
                println("$name found highest score of $highest")
                push!(results[name], (highest, elapsed_time))
            end
        end

        file = open("results/$(experiment_name)/ds$(dataset)_tl$(time_limit).json", "w")
        write(file, JSON.json(results))
		close(file)
        file = open("results/$(experiment_name)/ds$(dataset)_tl$(time_limit)_genimps.json", "w")
		write(file, JSON.json(improved_gen_results))
        close(file)
    end
end

main(
	generator=generate_jaya_narrow_survey,
	experiment_name="Jaya_narrow_survey_2",
	popsize=30,
	time_limit=220,
	datasets=1:9)

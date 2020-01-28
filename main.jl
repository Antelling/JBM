using JSON
include("compose.jl")
function generate_rao1_wide_survey(; time_limit::Int=15)
    configurations = Vector{Tuple{String,Any}}()
    push!(configurations, tuple("control", identity))
    for (search_name, search) in [("medium local search", MLS), ("fast local search", FLS), ("no local search", make_solution)]
        for n in [1, 2, 3, 5, 8, 13, 21]
            title = "Rao1 top$n bottom$n " * search_name
            alg = return_common_metaheuristics(n=n, time_limit=time_limit, ls=search)["Rao1"]
            push!(configurations, tuple(title, alg))
        end
    end
    configurations
end

function generate_CAC_wide_survey(; time_limit::Int=15)
    configurations = Vector{Tuple{String,Any}}()
    for (search_name, search) in [("medium local search", MLS), ("fast local search", FLS), ("no local search", make_solution)]
        for n in [1, 2, 3, 5, 8, 13, 21]
            title = "CAC $(n+1) parents " * search_name
            alg = return_common_metaheuristics(n=n, time_limit=time_limit, ls=search)["CAC"]
            push!(configurations, tuple(title, alg))
        end
    end
    configurations
end

function main(; time_limit::Number=10, generator::Function, experiment_name::String)
#    # first we need to collect the algorithms we will use
#    n_1__ls_slow = return_common_metaheuristics(n=1, time_limit=time_limit, ls=SLS)
#    n_1__ls_fast = return_common_metaheuristics(n=1, time_limit=time_limit, ls=FLS)
#    n_5__ls_slow = return_common_metaheuristics(n=5, time_limit=time_limit, ls=SLS)
#    n_5__ls_fast = return_common_metaheuristics(n=5, time_limit=time_limit, ls=FLS)
#    time_focused_metaheuristics = [
#        ("control", identity),
#        ("jaya top5 bottom5 fast local search", n_5__ls_fast["Jaya"]),
#        ("TBO top5 slow local search", n_5__ls_slow["TBO"]),
#        ("LBO fast local search", n_1__ls_fast["LBO"]),
#        ("CAC 2 parents fast local search", n_1__ls_fast["CAC"]),
#        ("GANM fast local search", n_1__ls_fast["GANM"]),
#        ("TLBO", cyclical_apply_closure([
#                            PMCC(ls=SLS,
#                                perturb=TBO_perturb,
#                                use_top=true,
#                                top_n=5,
#                                use_mean=true,
#                                max_iter=1),
#                            PMCC(ls=FLS,
#                                perturb=LBO_perturb,
#                                use_random=true,
#                                random_n=1, #LBO can only consider two solutions at once
#                                max_iter=1)],
#                            time_limit=time_limit,))
#    ]
#
#    n_1__ls_slow_max_constrained = return_common_metaheuristics(n=1, time_limit=time_limit, ls=SLS, use_max_fails=true)
#    n_5__ls_slow_max_constrained = return_common_metaheuristics(n=5, time_limit=time_limit, ls=SLS, use_max_fails=true)
#    fail_focused_metaheuristics = [
#        ("control", identity),
#        ("jaya top5 bottom5 slow local search", n_5__ls_slow_max_constrained["Jaya"]),
#        ("TBO top5 slow local search", n_5__ls_slow_max_constrained["TBO"]),
#        ("LBO slow local search", n_1__ls_slow_max_constrained["LBO"]),
#        ("CAC 2 parents slow local search", n_1__ls_slow_max_constrained["CAC"]),
#        ("GANM slow local search", n_1__ls_slow_max_constrained["GANM"]),
#        ("TLBO", cyclical_apply_closure([
#                            PMCC(ls=SLS,
#                                perturb=TBO_perturb,
#                                use_top=true,
#                                top_n=5,
#                                use_mean=true,
#                                max_iter=1),
#                            PMCC(ls=SLS,
#                                perturb=LBO_perturb,
#                                use_random=true,
#                                random_n=1, #LBO can only consider two solutions at once
#                                max_iter=1)],
#                            time_limit=time_limit,
#                            use_max_fails=true))
#    ]
#
#    metaheuristics = fail_focused ? fail_focused_metaheuristics : time_focused_metaheuristics
#    metaheuristics = generator(time_limit=time_limit)
    metaheuristics = [("rao1 n18 FLS", return_common_metaheuristics(n=18, time_limit=500, use_max_fails=true, max_fails=5, ls=FLS)["Rao1"])]
    
    run(`mkdir -p results/$(experiment_name)`)

    for dataset in 1:9
        problems = parse_file("./benchmark_problems/mdmkp_ct$(dataset).txt")

        results = Dict{String,Vector}()
        for (name, alg) in metaheuristics
            println(name)
            println(alg)
            println("about to crash")
            results[name] = Vector()
        end
        println("crashed")

        for (i, problem) in enumerate(problems)
            println("")
            println("")
            println("Testing problem number $i (case first order)")

            # generate an initial population using the greedy construct strategy
            # do not force feasibility
            pop::Population = greedy_construct(problem, 30, ls=MLS, force_valid=false)

            for (name, meta) in metaheuristics
                curr_pop = deepcopy(pop)
                start_time = time()
                meta(curr_pop, problem)
                end_time = time()
                highest = get_population_scores(curr_pop)[end]
                println("$name found highest score of $highest")
                push!(results[name], (highest, end_time - start_time))
            end
        end

        file = open("results/$(experiment_name)/ds$(dataset)_tl$(time_limit).json", "w")
        write(file, JSON.json(results))
        close(file)
    end
end

main(generator=identity, experiment_name="rao1_fast")

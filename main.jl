include("compose.jl")
using JSON

function main(; time_limit::Number=10, fail_focused::Bool=false)
    # first we need to collect the algorithms we will use
    n_1__ls_slow = return_common_metaheuristics(n=1, time_limit=time_limit, ls=SLS)
    n_1__ls_fast = return_common_metaheuristics(n=1, time_limit=time_limit, ls=FLS)
    n_5__ls_slow = return_common_metaheuristics(n=5, time_limit=time_limit, ls=SLS)
    n_5__ls_fast = return_common_metaheuristics(n=5, time_limit=time_limit, ls=FLS)
    time_focused_metaheuristics = [
        ("control", identity),
        ("jaya top5 bottom5 fast local search", n_5__ls_fast["Jaya"]),
        ("TBO top5 slow local search", n_5__ls_slow["TBO"]),
        ("LBO fast local search", n_1__ls_fast["LBO"]),
        ("CAC 2 parents fast local search", n_1__ls_fast["CAC"]),
        ("GANM fast local search", n_1__ls_fast["GANM"]),
        ("TLBO", cyclical_apply_closure([
                            PMCC(ls=SLS,
                                perturb=TBO_perturb,
                                use_top=true,
                                top_n=5,
                                use_mean=true,
                                max_iter=1),
                            PMCC(ls=FLS,
                                perturb=LBO_perturb,
                                use_random=true,
                                random_n=1, #LBO can only consider two solutions at once
                                max_iter=1)],
                            time_limit=time_limit,))
    ]

    n_1__ls_slow_max_constrained = return_common_metaheuristics(n=1, time_limit=time_limit, ls=SLS, use_max_fails=true)
    n_5__ls_slow_max_constrained = return_common_metaheuristics(n=5, time_limit=time_limit, ls=SLS, use_max_fails=true)
    fail_focused_metaheuristics = [
        ("control", identity),
        ("jaya top5 bottom5 slow local search", n_5__ls_slow_max_constrained["Jaya"]),
        ("TBO top5 slow local search", n_5__ls_slow_max_constrained["TBO"]),
        ("LBO slow local search", n_1__ls_slow_max_constrained["LBO"]),
        ("CAC 2 parents slow local search", n_1__ls_slow_max_constrained["CAC"]),
        ("GANM slow local search", n_1__ls_slow_max_constrained["GANM"]),
        ("TLBO", cyclical_apply_closure([
                            PMCC(ls=SLS,
                                perturb=TBO_perturb,
                                use_top=true,
                                top_n=5,
                                use_mean=true,
                                max_iter=1),
                            PMCC(ls=SLS,
                                perturb=LBO_perturb,
                                use_random=true,
                                random_n=1, #LBO can only consider two solutions at once
                                max_iter=1)],
                            time_limit=time_limit,
                            use_max_fails=true))
    ]

    genetic_metas_NLS = GA_mutation_survey(time_limit=5, ls=make_solution)
    genetic_metas_FLS = GA_mutation_survey(time_limit=5, ls=FLS)
    genetic_metas_SLS = GA_mutation_survey(time_limit=5, ls=SLS)
    genetic_metas = Vector{Tuple}()
    for (meta_collection, suffix) in [
            (genetic_metas_NLS, "NLS"),
            (genetic_metas_FLS, "FLS"),
            (genetic_metas_SLS, "SLS")]
        for (name, alg) in meta_collection
            name *= "_" * suffix
            push!(genetic_metas, (name, alg))
        end
    end

    metaheuristics = fail_focused ? fail_focused_metaheuristics : time_focused_metaheuristics

    # metaheuristics = genetic_metas

    for dataset in 1:9
        problems = parse_file("./benchmark_problems/mdmkp_ct$(dataset).txt")

        results = Dict{String,Vector}()
        for (name, alg) in metaheuristics
            results[name] = Vector()
        end

        for (i, problem) in enumerate(problems)
            println("Testing problem number $i (case first order)")

            # generate an initial population using the greedy construct strategy
            # do not force feasibility
            pop::Population = greedy_construct(problem, 30, ls=SLS, force_valid=false)
            println("initial population scores are $(get_population_scores(pop))\n")

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

        file = open("results/wide_survey/ds$(dataset)_tl$(time_limit)_ff$fail_focused.json", "w")
        write(file, JSON.json(results))
        close(file)
    end
end

main(time_limit=15, fail_focused=true)

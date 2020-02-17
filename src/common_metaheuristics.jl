function return_common_metaheuristics(;
        n::Int=1,
        time_limit::Number=10,
        ls::Function=make_solution,
        max_fails::Int=5,
        use_max_fails::Bool=false,
		update_extreme_solutions_during_iter::Bool=true)
    mapping = Dict{String,Function}()
    mapping["CAC"] = PMCC(ls=ls,
                     perturb=column_average_chances,
                     use_random=true,
                     random_n=n,
                     time_limit=time_limit,
                     max_fails=max_fails,
                     use_max_fails=use_max_fails)

     mapping["GANM"] = PMCC(ls=ls,
                      perturb=GANM_perturb,
                      use_random=true,
                      random_n=1,
                      time_limit=time_limit,
                      max_fails=max_fails,
                      use_max_fails=use_max_fails)

    mapping["Jaya"] = PMCC(ls=ls,
                    perturb=jaya_perturb,
                    use_top=true,
                    top_n=n,
                    use_bottom=true,
                    bottom_n=n,
                    time_limit=time_limit,
                    max_fails=max_fails,
                    use_max_fails=use_max_fails)

    mapping["TBO"] = PMCC(ls=ls,
                    perturb=TBO_perturb,
                    use_top=true,
                    top_n=n,
                    use_mean=true,
                    time_limit=time_limit,
                    max_fails=max_fails,
                    use_max_fails=use_max_fails)

    mapping["LBO"] = PMCC(ls=ls,
                     perturb=LBO_perturb,
                     use_random=true,
                     random_n=1, #LBO can only consider two solutions at once
                     time_limit=time_limit,
                     max_fails=max_fails,
                     use_max_fails=use_max_fails)

    mapping["Rao2"] = PMCC(ls=ls,
                    perturb=rao2_perturb,
                    use_top=true,
                    top_n=n,
                    use_bottom=true,
                    bottom_n=n,
                    use_random=true,
                    random_n=1,
                    time_limit=time_limit,
                    max_fails=max_fails,
                    use_max_fails=use_max_fails,
					update_extreme_solutions_during_iter=update_extreme_solutions_during_iter)

    mapping["Rao1"] = PMCC(ls=ls,
                    perturb=rao1_perturb,
                    use_top=true,
                    top_n=n,
                    use_bottom=true,
                    bottom_n=n,
                    time_limit=time_limit,
                    max_fails=max_fails,
                    use_max_fails=use_max_fails,
					update_extreme_solutions_during_iter=update_extreme_solutions_during_iter)

    mapping["TLBO"] = cyclical_apply_closure([
                        PMCC(ls=ls,
                            perturb=TBO_perturb,
                            use_top=true,
                            top_n=n,
                            use_mean=true,
                            max_iter=1),
                        PMCC(ls=ls,
                            perturb=LBO_perturb,
                            use_random=true,
                            random_n=1, #LBO can only consider two solutions at once
                            max_iter=1)],
                        time_limit=time_limit)

    return mapping
end


function GA_mutation_survey(;
    time_limit::Number=10,
    ls::Function=make_solution,
    max_fails::Int=5,
    use_max_fails::Bool=false)
    mapping = Dict{String,Function}()

    for percent in [0.0, 0.01, 0.02, 0.03, 0.05, 0.08, 0.13, 0.21, 0.34]
        perturb = PMCPC(GA_perturb, Dict(:mutation_percent=>percent))
        mapping["GA_$percent"] = PMCC(ls=ls,
                         perturb=perturb,
                         use_random=true,
                         random_n=1,
                         time_limit=time_limit,
                         max_fails=max_fails,
                         use_max_fails=use_max_fails)
    end

    mapping
end

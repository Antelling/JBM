function return_common_metaheuristics(n, timelimit) #TODO: add n_samples
    mapping = Dict{String,Function}()
    mapping["GA$(n+1)[VND]"] = PMCC(ls=VND,
                         perturb=column_average_chances,
                         use_random=true,
                         random_n=n,
                         time_limit=timelimit)

    mapping["GA$(n+1)[LF]"] = PMCC(ls=local_flip,
                         perturb=column_average_chances,
                         use_random=true,
                         random_n=n,
                         time_limit=timelimit)

    mapping["GA$(n+1)[LS]"] = PMCC(ls=local_swap,
                      perturb=column_average_chances,
                      use_random=true,
                      random_n=n,
                      time_limit=timelimit)

    return mapping
end

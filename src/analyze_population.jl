function get_population_scores(pop::Population)
    scores = [sol.score for sol in pop]
    return sort!(scores)
end

function assure_unique(pop::Population)
    for i in 1:length(pop)
        for j in 1:length(pop)
            if i == j
                continue
            end
            @assert pop[i].bitlist != pop[j].bitlist
         end
     end
end

function count_valid(pop::Population, problem::Problem)
    return sum([is_valid(s, problem) ? 1 : 0 for s in pop])
end

function get_best_solution(pop::Population)
    best_sol::Solution = pop[1]
    for s in pop
        if s.score > best_sol.score
            best_sol = s
        end
    end
    return deepcopy(best_sol) 
end

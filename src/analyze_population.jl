function get_population_scores(pop::Population)
    scores = [sol.score for sol in pop]
    return sort!(scores)
end
    

function column_average_chances(
        first_sol::Solution;
        random_sols::Population,
        top_sol::Solution,
        bottom_sol::Solution,
        mean_of_sols::Vector{Float64}=0,
        n_samples::Int=1)::BitArray

    n_dimensions = length(first_sol.bitlist)
    averages::Vector{Float64} = zeros(n_dimensions)
    for sol in random_sols
        averages .+= sol.bitlist
    end
    averages .+= first_sol.bitlist
    averages /= length(random_sols) + 1
    return [rand() < percent for percent in averages]
end

function jaya_perturb(
        first_sol::Solution;
        random_sols::Population,
        top_sol::Solution,
        bottom_sol::Solution,
        mean_of_sols::Vector{Float64}=0,
        n_samples::Int=1)::BitArray
        return [bit + rand([0, 1])*(top_sol[i]-bit) - rand([0, 1])*(bottom_sol[i]-bit) > 0 for (i, bit) in enumerate(first_sol)]
end

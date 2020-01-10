function column_average_chances(
        first_sol::Solution;
        random_sols::Population,
        top_sol::Solution,
        bottom_sol::Solution,
        mean_of_sols::Vector{Float64},
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
        mean_of_sols::Vector{Float64},
        n_samples::Int=1)::BitArray
        return [bit + rand([0, 1])*(top_sol.bitlist[i]-bit) - rand([0, 1])*(bottom_sol.bitlist[i]-bit) > 0 for (i, bit) in enumerate(first_sol.bitlist)]
end

function TBO_perturb(
    first_sol::Solution;
    random_sols::Population,
    top_sol::Solution,
    bottom_sol::Solution,
    mean_of_sols::Vector{Float64},
    n_samples::Int=1)::BitArray
    return [bit +
        rand([0,1]) * (top_sol.bitlist[i] - (rand([1, 2])) * (rand() < mean_of_sols[i])) > 0
        for (i, bit) in enumerate(first_sol.bitlist)]

end

function LBO_perturb(
        first_sol::Solution;
        random_sols::Population,
        top_sol::Solution,
        bottom_sol::Solution,
        mean_of_sols::Vector{Float64},
        n_samples::Int=1)::BitArray

    second_sol = random_sols[1]
    if second_sol.score > first_sol.score #assure first_sol is the teacher
        temp = first_sol
        first_sol = second_sol
        second_sol = temp
    end
    return [second_sol.bitlist[j] + rand([0,1]) * (first_sol.bitlist[j] - second_sol.bitlist[j]) for j in 1:length(first_sol.bitlist)]
end

function GA_perturb(
        first_sol::Solution;
        random_sols::Population,
        top_sol::Solution,
        bottom_sol::Solution,
        mean_of_sols::Vector{Float64},
        n_samples::Int=1,
        mutation_percent::Float64=.02)::BitArray

    n_dimensions = length(first_sol.bitlist)
    pivot = rand(2:n_dimensions)
    new_sol = vcat(first_sol.bitlist[1:pivot-1], random_sols[1].bitlist[pivot:end])

    #now we mutate the new solution
    n_mutations = Int(round(mutation_percent*n_dimensions))
    for _ in 1:n_mutations
        i = rand(1:n_dimensions)
        new_sol[i] = !new_sol[i]
    end
    new_sol
end

"""Genetic Algorithm No Mutation"""
function GANM_perturb(
        first_sol::Solution;
        random_sols::Population,
        top_sol::Solution,
        bottom_sol::Solution,
        mean_of_sols::Vector{Float64})::BitArray

    n_dimensions = length(first_sol.bitlist)
    pivot = rand(2:n_dimensions)
    vcat(first_sol.bitlist[1:pivot-1], random_sols[1].bitlist[pivot:end])
end

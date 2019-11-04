module MS #Metaheuristic Structs

BitList = Vector{Bool}

struct Solution
    bitlist::BitList
    score::Int64
end

Population = Vector{Solution}

struct ProblemInstance
    objective::Vector{Int}
    upper_bounds::Vector{Tuple{Vector{Int},Int}}
    lower_bounds::Vector{Tuple{Vector{Int},Int}}
    index::Int
end

end

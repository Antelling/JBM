BitList = Vector{Bool}

struct Solution
    bitlist::BitList
    score::Int64
end

Population = Vector{Solution}

struct Problem
    objective::Vector{Int}
    upper_bounds::Vector{Tuple{Vector{Int},Int}}
    lower_bounds::Vector{Tuple{Vector{Int},Int}}
end

function identity(x, y) return x end

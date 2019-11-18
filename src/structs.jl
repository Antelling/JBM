struct Solution
    bitlist::BitArray
    score::Int64
end

Population = Vector{Solution}

struct Problem
    objective::Vector{Int}
    upper_bounds::Vector{Tuple{Vector{Int},Int}}
    lower_bounds::Vector{Tuple{Vector{Int},Int}}
end

function identity(x, y) return x end

function contains(pop::Population, sol::Solution)
    for s in pop
        if sol.bitlist == s.bitlist
            return true
        end
    end
    return false
end

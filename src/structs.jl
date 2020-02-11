struct Solution
    bitlist::BitArray
    score::Int64
end

const Population = Vector{Solution}

struct Problem_ID
	dataset::Int
	instance::Int
	case::Int
end

struct Problem
    objective::Vector{Int}
    upper_bounds::Vector{Tuple{Vector{Int},Int}}
    lower_bounds::Vector{Tuple{Vector{Int},Int}}
	id::Problem_ID
end

function identity(x, y) return x end
function pmeta_control(x, y) return [] end

function contains(pop::Population, sol::Solution)
    for s in pop
        if sol.bitlist == s.bitlist
            return true
        end
    end
    return false
end

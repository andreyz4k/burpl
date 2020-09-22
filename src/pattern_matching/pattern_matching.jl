export PatternMatching
module PatternMatching

abstract type Matcher end


compare_values(value1, value2) = value1 == value2 ? value2 : match(value1, value2)

match(val1, val2) = nothing
function match(val1::Dict, val2::Dict)
    if !issetequal(keys(val1), keys(val2))
        return nothing
    end
    match = Dict()
    for key in keys(val1)
        m = compare_values(val1[key], val2[key])
        if isnothing(m)
            return nothing
        end
        match[key] = m
    end
    return match
end

match(value1, value2::Matcher) = match(value2, value1)

unpack_value(value) = [value]

import ..Complexity:get_complexity
using Statistics:mean

get_complexity(value::Matcher)::Float64 =
    mean(get_complexity, unpack_value(value))


include("either.jl")
include("update_value.jl")


end

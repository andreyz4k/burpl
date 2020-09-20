export PatternMatching
module PatternMatching

abstract type Matcher end


compare_values(value1, value2) = value1 == value2 ? value2 : match(value1, value2)

match(val1, val2) = nothing
match(::Nothing, value) = value
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
match(::Nothing, value2::Matcher) = value2

unpack_value(value) = [value]


include("either.jl")
include("find_const.jl")
include("update_value.jl")

end

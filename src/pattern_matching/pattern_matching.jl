export PatternMatching
module PatternMatching

abstract type Matcher{T} end

common_value(value1, value2) = value1 == value2 ? value2 : match(value1, value2)

match(val1, val2) = nothing

match(value1::Matcher, value2) = match(value2, value1)
function match(val1::AbstractDict, val2::AbstractDict)
    if !issetequal(keys(val1), keys(val2))
        return nothing
    end
    result = Dict()
    for key in keys(val1)
        m = common_value(val1[key], val2[key])
        if isnothing(m)
            return nothing
        end
        result[key] = m
    end
    return result
end

function match(val1::AbstractVector, val2::AbstractVector)
    if length(val1) != length(val2)
        return nothing
    end
    result = []
    for (v1, v2) in zip(val1, val2)
        m = common_value(v1, v2)
        if isnothing(m)
            return nothing
        end
        push!(result, m)
    end
    result
end


compare_values(val1::Matcher, val2, candidates, func, types, same_type=true) = false

function compare_values(val1::AbstractDict, val2::AbstractDict, candidates, func, types, same_type=true)
    if !issetequal(keys(val1), keys(val2))
        return false
    end
    return all(compare_values(val1[key], val2[key], candidates, func, types, same_type) for key in keys(val1))
end

function compare_values(val1::AbstractVector, val2::AbstractVector, candidates, func, types, same_type=true)
    if length(val1) != length(val2)
        return false
    end
    return all(compare_values(v1, v2, candidates, func, types, same_type) for (v1, v2) in zip(val1, val2))
end

function compare_values(val1, val2, candidates, func, types, same_type=true)
    if !isa(val1, types)
        return false
    end
    if same_type
        T = typeof(val1)
    else
        T = types
    end
    check_type(::Any) = false
    check_type(::Matcher{S}) where {S} = S <: T
    if !isa(val2, T) && !check_type(val2)
        return false
    end
    return func(val1, val2, candidates)
end


unpack_value(value) = [value]

import ..Complexity:get_complexity
using Statistics:mean

get_complexity(value::Matcher)::Float64 =
    mean(get_complexity, unpack_value(value))


include("either.jl")
include("array_prefix.jl")
include("object_shape.jl")
include("update_value.jl")


end

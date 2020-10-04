export PatternMatching
module PatternMatching

abstract type Matcher{T} end

common_value(value1, value2) = value1 == value2 ? value2 : _common_value(value1, value2)

_common_value(val1, val2) = nothing

_common_value(value1::Matcher, value2) = _common_value(value2, value1)
function _common_value(val1::AbstractDict, val2::AbstractDict)
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

function _common_value(val1::AbstractVector, val2::AbstractVector)
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


compare_values(val1::Matcher, val2, candidates, func, types) = false

function compare_values(val1::AbstractDict, val2::AbstractDict, candidates, func, types)
    if !issetequal(keys(val1), keys(val2))
        return false
    end
    return all(compare_values(val1[key], val2[key], candidates, func, types) for key in keys(val1))
end

function compare_values(val1::AbstractVector, val2::AbstractVector, candidates, func, types)
    if length(val1) != length(val2)
        return false
    end
    return all(compare_values(v1, v2, candidates, func, types) for (v1, v2) in zip(val1, val2))
end

function compare_values(val1, val2, candidates, func, types)
    if !isa(val1, types)
        return false
    end
    T = typeof(val1)
    if !isa(val2, T) && !isa(val2, Matcher{T})
        return false
    end
    return func(val1, val2, candidates)
end

compare_values(value1, value2) = value1 == value2 ? value2 : match(value1, value2)

match(val1, val2) = nothing
function match(val1::Dict, val2::Dict)
    if !issetequal(keys(val1), keys(val2))
        return nothing
    end
    result = Dict()
    for key in keys(val1)
        m = compare_values(val1[key], val2[key])
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
        m = compare_values(v1, v2)
        if isnothing(m)
            return nothing
        end
        push!(result, m)
    end
    result
end

match(value1, value2::Matcher) = match(value2, value1)

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

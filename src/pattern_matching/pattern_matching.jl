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


check_match(value1, value2) = value1 == value2 ? true : _check_match(value1, value2)

_check_match(val1, val2) = false
function _check_match(val1::AbstractDict, val2::AbstractDict)
    if !issetequal(keys(val1), keys(val2))
        return false
    end
    return all(check_match(val1[key], val2[key]) for key in keys(val1))
end

function _check_match(val1::AbstractVector, val2::AbstractVector)
    if length(val1) != length(val2)
        return false
    end
    return all(check_match(v1, v2) for (v1, v2) in zip(val1, val2))
end

apply_func(value, func, param) = func(value, param)
apply_func(value::Vector, func, param) = [apply_func(v, func, param) for v in value]
apply_func(value::T, func, param::T) where T <: Vector = [apply_func(v, func, p) for (v, p) in zip(value, param)]
apply_func(value::Dict, func, param) = Dict(key => apply_func(v, func, param) for (key, v) in value)


check_type(existing::Type, expected::Type) = existing <: expected
check_type(::Type{Dict{K,V}}, expected::Type) where {K,V} = check_type(V, expected)
check_type(::Type{Vector{T}}, expected::Type) where T = check_type(T, expected)


unpack_value(value) = [value]

function unpack_value(value::AbstractDict)
    out = [[]]
    for (key, val) in value
        out = [[part..., key => v] for part in out for v in unpack_value(val)]
    end
    [Dict(k => v for (k, v) in pairs) for pairs in out]
end

function unpack_value(value::AbstractVector)
    out = [[]]
    for val in value
        out = [[part..., v] for part in out for v in unpack_value(val)]
    end
    out
end

import ..Complexity:get_complexity
using Statistics:mean

get_complexity(value::Matcher)::Float64 =
    mean(get_complexity, unpack_value(value))


include("either.jl")
include("array_prefix.jl")
include("object_shape.jl")
include("update_value.jl")


end

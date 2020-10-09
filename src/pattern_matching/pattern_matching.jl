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


compare_values(val1::Matcher, val2, candidates, func, types, same_type=true, first_symbol=:(T)) = error("try to match from matcher")

function compare_values(val1::AbstractDict, val2::AbstractDict, candidates, func, types, same_type=true, first_symbol=:(T))
    if !issetequal(keys(val1), keys(val2))
        return false
    end
    return all(compare_values(val1[key], val2[key], candidates, func, types, same_type, first_symbol) for key in keys(val1))
end

function compare_values(val1::AbstractVector, val2::AbstractVector, candidates, func, types, same_type=true, first_symbol=:(T))
    if length(val1) != length(val2)
        return false
    end
    return all(compare_values(v1, v2, candidates, func, types, same_type, first_symbol) for (v1, v2) in zip(val1, val2))
end

type_checks = Dict()

function compare_values(val1, val2, candidates, func, types, same_type=true, first_symbol=:(T))
    if !haskey(type_checks, (types, same_type, first_symbol))
        fname = gensym("check_type")
        @eval $(fname)(::Any, ::Any) = false
        if same_type
            @eval $(fname)(::$first_symbol, ::T) where {T <: $types} = true
            @eval $(fname)(::$first_symbol, ::Matcher{T}) where {T <: $types} = true
        else
            @eval $(fname)(::$first_symbol, ::S) where {T <: $types,S <: $types} = true
            @eval $(fname)(::$first_symbol, ::Matcher{S}) where {T <: $types,S <: $types} = true
        end
        @eval out = $(fname)
        type_checks[(types, same_type, first_symbol)] = out
    end
    if !Base.invokelatest(type_checks[(types, same_type, first_symbol)], val1, val2)
        return false
    end
    return func(val1, val2, candidates)
end


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

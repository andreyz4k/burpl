export Complexity
module Complexity

using ..ObjectPrior:Object

get_complexity(v::Any)::Float64 = length(repr(v))

get_complexity(::Int)::Float64 = 1

get_complexity(value::Tuple)::Float64 =
    3 + sum(get_complexity(v) for v in value) * 0.95^(length(value) - 1)

get_complexity(value::AbstractVector)::Float64 =
    5 + sum(Float64[get_complexity(v) for v in value]) * 0.95^(length(value) - 1)

get_complexity(value::AbstractArray{Int,2})::Float64 =
    5 + sum(value .!= -1) * 4 * 0.95^(sum(value .!= -1) - 1)

get_complexity(value::String)::Float64 = length(value)

get_complexity(value::Object)::Float64 = get_complexity(value.shape) + get_complexity(value.position)

function get_complexity(value::AbstractDict)::Float64
    denominator = 0
    for v in values(value)
        if isa(v, Array) || isa(v, Set) || isa(v, Tuple)
            denominator += length(v)
        end
    end
    if denominator > 0
        denominator /= length(value)
    else
        denominator = 1
    end
    denominator = min(denominator, length(value))
    return 2 + sum(get_complexity(k) for k in keys(value)) / length(value) +
        sum(get_complexity(v) for v in values(value)) / denominator
end

include("zip_longest.jl")

function _get_variability(items)
    items = Set(items)
    if in(nothing, items)
        delete!(items, nothing)
        base_res = 1
    else
        base_res = 0
    end

    f = first(items)
    if isa(f, Int64) || isa(f, Bool)
        return maximum(items) - minimum(items) + base_res + 1
    end
    if isa(f, Tuple)
        return reduce((x, y) -> min(x, 1000) * min(y, 1000), (min(_get_variability(values), 1000) for values in zip_longest(items...)), init=1) + base_res
    end
    if isa(f, Object)
        return min(_get_variability(o.shape for o in items), 1000) *
            min(_get_variability(o.position for o in items), 1000)
    end
    if isa(f, Array{Int64,2})
        return min(_get_variability(tuple([(ind[1], ind[2], item[ind]) for ind in eachindex(view(item, 1:size(item)[1], 1:size(item)[2])) if item[ind] != -1]...) for item in items), 1000)
    end
end

_is_one_hot(items::AbstractSet) = all(_is_one_hot(v) for v in items)
_is_one_hot(value::Tuple) = all(v == 1 || v == 0 for v in value) && sum(value) == 1


function get_generability(items)::Float64
    items = Set(items)
    f = first(items)
    if isa(f, Bool)
        return 3 - length(items)
    end
    if isa(f, Tuple)
        if _is_one_hot(items)
            return length(f) - length(items) + 1
        end
    end
    if isa(f, Int64) || isa(f, Tuple) ||
            isa(f, Array{Int64,2}) || isa(f, Object)
        return _get_variability(items) - length(items) + 1
    end
    return 1000
end

end

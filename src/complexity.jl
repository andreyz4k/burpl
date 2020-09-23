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
    5 + sum(value .!= -1) * 3 * 0.95^(sum(value .!= -1) - 1) + *(size(value)...)

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

end

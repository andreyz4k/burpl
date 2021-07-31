module Complexity

using ..DataStructures: Entry

get_complexity(v::Any)::Float64 = length(repr(v))

get_complexity(entry::Entry)::Float64 = sum(get_complexity(v) for v in entry.values)

get_complexity(::Int)::Float64 = 1

get_complexity(value::Tuple)::Float64 =
    3 + sum(get_complexity(v) for v in value) * (0.5 + 0.5 * 0.95^(length(value) - 1))

get_complexity(value::AbstractVector)::Float64 =
    5 + sum(Float64[get_complexity(v) for v in value]) * (0.5 + 0.5 * 0.95^(length(value) - 1))

get_complexity(value::AbstractArray{Int,2})::Float64 =
    5 + sum(value .!= -1) * 8 * (0.5 + 0.5 * 0.95^(sum(value .!= -1) - 1))

get_complexity(value::String)::Float64 = length(value)

function get_complexity(value::AbstractDict)::Float64
    denominator = 0
    if isempty(value)
        return 2
    end
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
    return 2 +
           sum(Float64[get_complexity(k) for k in keys(value)]) / length(value) +
           sum(Float64[get_complexity(v) for v in values(value)]) / denominator
end

end

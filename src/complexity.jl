module Complexity

get_complexity(v::Any)::Int = length(repr(v))

get_complexity(::Int) = 1
get_complexity(value::Tuple) =
    3 + sum(get_complexity(v) for v in value) * 0.95^(length(value) - 1)
get_complexity(value::Union{Array,Set}) =
    5 + sum(get_complexity(v) for v in value) * 0.95^(length(value) - 1)
get_complexity(value::String) = length(value)
function get_complexity(value::Dict)
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
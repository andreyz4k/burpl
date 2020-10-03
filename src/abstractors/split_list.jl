

struct SplitList <: AbstractorClass end

@memoize priority(::SplitList) = 15

@memoize abs_keys(::SplitList) = ["size", "item"]

@memoize abs_keys(cls::SplitList, key::String, max_count::Int) = [key * "|" * abs_keys(cls)[1], [key * "|" * abs_keys(cls)[2] * string(i) for i in 1:max_count]...]
SplitList(key, max_count, to_abs) = Abstractor(SplitList(), key, max_count, to_abs)

function Abstractor(cls::SplitList, key::String, max_count::Int, to_abs::Bool)
    if to_abs
        return Abstractor(cls, true, detail_keys(cls, key), abs_keys(cls, key, max_count))
    else
        return Abstractor(cls, false, abs_keys(cls, key, max_count), detail_keys(cls, key))
    end
end

init_create_check_data(::SplitList, key, solution) = Dict("max_count" => 0)

function check_task_value(::SplitList, value::Vector, data, aux_values)
    data["max_count"] = max(data["max_count"], length(value))
    true
end

function create_abstractors(cls::SplitList, data, key, found_aux_keys)
    if data["max_count"] > 1
        [(priority(cls), (to_abstract = Abstractor(cls, key, data["max_count"], true),
                             from_abstract = Abstractor(cls, key, data["max_count"], false)))]
    else
        []
    end
end

function to_abstract_value(p::Abstractor, ::SplitList, source_value)
    result = Dict{String,Any}(p.output_keys[1] => length(source_value))
    for (i, item) in enumerate(source_value)
        result[p.output_keys[i + 1]] = item
    end
    result
end

fetch_abs_values(p::Abstractor, ::SplitList, task_data) =
    [task_data[p.input_keys[i + 1]] for i in 1:task_data[p.input_keys[1]]]

from_abstract_value(p::Abstractor, ::SplitList, source_values) =
    Dict(p.output_keys[1] => source_values[2:1 + source_values[1]])

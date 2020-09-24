

struct SplitList <: AbstractorClass end

@memoize priority(p::SplitList) = 15

@memoize abs_keys(p::SplitList) = ["size", "item"]

@memoize abs_keys(cls::SplitList, key::String, max_count::Int) = [key * "|" * abs_keys(cls)[1], [key * "|" * abs_keys(cls)[2] * string(i) for i in 1:max_count]...]
SplitList(key, max_count, to_abs) = Abstractor(SplitList(), key, max_count, to_abs)

function Abstractor(cls::SplitList, key::String, max_count::Int, to_abs::Bool)
    if to_abs
        return Abstractor(cls, true, detail_keys(cls, key), abs_keys(cls, key, max_count))
    else
        return Abstractor(cls, false, abs_keys(cls, key, max_count), detail_keys(cls, key))
    end
end

init_create_check_data(cls::SplitList, key, solution) = Dict("max_count" => 0)

function check_task_value(cls::SplitList, value::Vector, data, aux_values)
    data["max_count"] = max(data["max_count"], length(value))
    true
end

create_abstractors(cls::SplitList, data, key, found_aux_keys) =
    [(priority(cls), (to_abstract = Abstractor(cls, key, data["max_count"], true),
                      from_abstract = Abstractor(cls, key, data["max_count"], false)))]

function to_abstract_value(p::Abstractor, cls::SplitList, source_value, aux_values)
    result = Dict{String,Any}(p.output_keys[1] => length(source_value))
    for (i, item) in enumerate(source_value)
        result[p.output_keys[i + 1]] = item
    end
    result
end

fetch_abs_values(p::Abstractor, cls::SplitList, task_data) =
    [task_data[p.input_keys[i + 1]] for i in 1:task_data[p.input_keys[1]]]

from_abstract_value(p::Abstractor, cls::SplitList, source_values) =
    Dict(p.output_keys[1] => source_values[2:1 + source_values[1]])


using ..ObjectPrior:Object,get_color

struct GroupObjectsByColor <: AbstractorClass end

GroupObjectsByColor(key, to_abs) = Abstractor(GroupObjectsByColor(), key, to_abs)
@memoize abs_keys(p::GroupObjectsByColor) = ["grouped", "group_keys"]

init_create_check_data(cls::GroupObjectsByColor, key, solution) = []

function check_task_value(cls::GroupObjectsByColor, value::AbstractVector{Object}, data, aux_values)
    colors = Set()
    for obj in value
        push!(colors, get_color(obj))
    end
    push!(data, colors)
    return true
end

function create_abstractors(cls::GroupObjectsByColor, data, key, found_aux_keys)
    if any(length(colors) > 1 for colors in data)
        return invoke(create_abstractors, Tuple{AbstractorClass,Any,Any,Any}, cls, data, key, found_aux_keys)
    end
    return []
end

function to_abstract_value(p::Abstractor, cls::GroupObjectsByColor, source_value, aux_values)
    results = DefaultDict(() -> Object[])
    for obj in source_value
        key = get_color(obj)
        push!(results[key], obj)
    end
    return Dict(
        p.output_keys[1] => Dict(results),
        p.output_keys[2] => sort(collect(keys(results)))
    )
end

function from_abstract_value(p::Abstractor, cls::GroupObjectsByColor, source_values)
    data, keys = source_values
    results = reduce(
        vcat,
        [isa(data, AbstractDict) ? data[key] : data for key in keys],
        init=Object[]
    )
    return Dict(p.output_keys[1] => results)
end

function from_abstract(p::Abstractor, cls::GroupObjectsByColor, previous_data::Dict)::Dict
    out_data = copy(previous_data)
    source_values = fetch_input_values(p, out_data)

    merge!(out_data, from_abstract_value(p, cls, source_values))

    return out_data
end

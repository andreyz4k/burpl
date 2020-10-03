
using ..ObjectPrior:Object,get_color

struct GroupObjectsByColor <: AbstractorClass end

GroupObjectsByColor(key, to_abs) = Abstractor(GroupObjectsByColor(), key, to_abs)
@memoize abs_keys(::GroupObjectsByColor) = ["grouped", "group_keys"]

init_create_check_data(::GroupObjectsByColor, key, solution) = Dict("effective" => false)

function check_task_value(::GroupObjectsByColor, value::AbstractVector{Object}, data, aux_values)
    colors = Set()
    for obj in value
        push!(colors, get_color(obj))
    end
    data["effective"] |= length(colors) > 1
    return true
end

function to_abstract_value(p::Abstractor, ::GroupObjectsByColor, source_value)
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

function from_abstract_value(p::Abstractor, ::GroupObjectsByColor, source_values)
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

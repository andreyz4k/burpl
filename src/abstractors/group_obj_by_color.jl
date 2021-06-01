
using ..ObjectPrior:Object,get_color

struct GroupObjectsByColor <: AbstractorClass end

GroupObjectsByColor(key, to_abs) = Abstractor(GroupObjectsByColor(), key, to_abs)
abs_keys(::GroupObjectsByColor) = ["grouped", "group_keys"]

init_create_check_data(::GroupObjectsByColor, key, solution) = Dict("effective" => false)

function check_task_value(::GroupObjectsByColor, value::AbstractSet{Object}, data, aux_values)
    colors = Set()
    for obj in value
        push!(colors, get_color(obj))
    end
    data["effective"] |= length(colors) > 1
    return true
end

function to_abstract_value(p::Abstractor{GroupObjectsByColor}, source_value)
    results = DefaultDict(() -> Set{Object}())
    for obj in source_value
        key = get_color(obj)
        push!(results[key], obj)
    end
    return Dict(
        p.output_keys[1] => Dict(k => v for (k, v) in results),
        p.output_keys[2] => Set{Color}(keys(results))
    )
end


function wrap_func_call_dict_value(p::Abstractor{GroupObjectsByColor}, func::Function, wrappers::AbstractVector{Function}, source_values...)
    if func == from_abstract_value
        wrap_func_call_value(p, func, wrappers, source_values...)
    else
        invoke(wrap_func_call_dict_value, Tuple{Abstractor,Function,AbstractVector{Function},Vararg{Any}}, p, func, wrappers, source_values...)
    end
end

function from_abstract_value(p::Abstractor{GroupObjectsByColor}, data, keys)
    results = reduce(
        union,
        values(data),
        init=Set{Object}()
    )
    return Dict(p.output_keys[1] => results)
end

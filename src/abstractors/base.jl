
abstract type Abstractor end

Base.show(io::IO, cls::Type{<:Abstractor}) = print(io, cls.name.name)

using PartialFunctions

function try_apply_abstractor(branch, key, abstractor)
    value = branch[key]
    abs_values = to_abstract(abstractor, value)
    if isnothing(abs_values)
        return nothing
    end
    new_keys = []
    if haskey(branch.known_fields, key)
        for (k, val) in zip(abs_keys(abstractor), abs_values)
            out_key = "$key|$k"
            push!(new_keys, out_key)
            branch.known_fields[out_key] = val
        end
        push!(branch.operations, Operation(to_abstract $ abstractor, [key], new_keys))
    else
        for (k, val) in zip(abs_keys(abstractor), abs_values)
            new_key = "$key|$k"
            push!(new_keys, new_key)
            branch.unknown_fields[new_key] = val
            branch.fill_percentages[new_key] = 0.0
        end
        push!(branch.operations, Operation(from_abstract $ abstractor, new_keys, [key]))
    end
    return new_keys
end

function to_abstract(cls::Type, value::Entry)
    results = []
    for val in value.values
        res = wrap_inner_function(cls, to_abstract_inner, value.type, val)
        if isnothing(res)
            return nothing
        end
        push!(results, res)
    end
    out_types = return_types(cls, value.type)
    return tuple((Entry(type, [r[i] for r in results]) for (i, type) in enumerate(out_types))...)
end

wrap_inner_function(cls, func, type, value) = func(cls, type, value)

using ..DataStructures: Either, Option
function wrap_inner_function(cls, func, type, value::Either)
    out_options = []
    for option in value.options
        out = wrap_inner_function(cls, func, type, option.value)
        if isnothing(out)
            return nothing
        end
        push!(out_options, [Option(v, option.option_hash) for v in out])
    end
    results = tuple((Either(collect(options), []) for options in zip(out_options...))...)
    for (i, res_item) in enumerate(results)
        push!(res_item.connected_items, value)
        append!(res_item.connected_items, value.connected_items)
        append!(res_item.connected_items, results[1:i-1])
        append!(res_item.connected_items, results[i+1:end])
    end
    for item in value.connected_items
        append!(item.connected_items, results)
    end
    append!(value.connected_items, results)
    return results
end

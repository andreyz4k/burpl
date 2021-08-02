
abstract type Abstractor end

Base.show(io::IO, cls::Type{<:Abstractor}) = print(io, cls.name.name)

using PartialFunctions
using ..DataStructures: Either, Option

_has_either(::Any) = false
_has_either(::Either) = true
_has_either(val::Vector) = any(_has_either(v) for v in val)

function try_apply_abstractor(branch, key, abstractor)
    value = branch[key]
    abs_values = to_abstract(abstractor, value)
    if isnothing(abs_values)
        return nothing
    end

    affected_either_groups = filter(gr -> in(key, gr), branch.either_groups)
    new_eithers = [i for (i, entry) in enumerate(abs_values) if _has_either(entry.values)]

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
        if !isempty(new_eithers)
            if !isempty(affected_either_groups)
                for group in affected_either_groups
                    union!(group, [new_keys[i] for i in new_eithers])
                end
            else
                push!(branch.either_groups, Set(new_keys[i] for i in new_eithers))
            end
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

function wrap_inner_function(cls, func, type, value::Either)
    out_options = []
    for option in value.options
        out = wrap_inner_function(cls, func, type, option.value)
        if isnothing(out)
            return nothing
        end
        push!(out_options, [Option(v, option.option_hash) for v in out])
    end
    return tuple((Either(collect(options)) for options in zip(out_options...))...)
end

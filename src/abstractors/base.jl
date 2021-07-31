
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
        for (k, val) in abs_values
            out_key = "$key|$k"
            push!(new_keys, out_key)
            branch.known_fields[out_key] = val
        end
        push!(branch.operations, Operation(to_abstract $ abstractor, [key], new_keys))
    else
        for (k, val) in abs_values
            new_key = "$key|$k"
            push!(new_keys, new_key)
            branch.unknown_fields[new_key] = val
            branch.fill_percentages[new_key] = 0.0
        end
        push!(branch.operations, Operation(from_abstract $ abstractor, new_keys, [key]))
    end
    return new_keys
end

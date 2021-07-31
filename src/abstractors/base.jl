
abstract type Abstractor end

using ..DataStructures: Entry, Operation

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
        push!(branch.operations, Operation((abstractor, to_abstract), [key], new_keys))
    else
        for (k, val) in abs_values
            new_key = "$key|$k"
            push!(new_keys, new_key)
            branch.unknown_fields[new_key] = val
            branch.fill_percentages[new_key] = 0.0
        end
        push!(branch.operations, Operation((abstractor, from_abstract), new_keys, [key]))
    end
    return new_keys
end

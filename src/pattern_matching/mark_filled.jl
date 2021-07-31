
using ..Complexity: get_complexity

function mark_filled_field(branch, key)
    branch.fill_percentages[key] = 1.0
    branch.known_fields[key] = branch.unknown_fields[key]
    delete!(branch.unknown_fields, key)
    updated_weights = Set([key])
    for op in reverse(branch.operations)
        if any(in(k, updated_weights) for k in op.input_keys)
            full_input_complexity = 0.0
            explained_input_complexity = 0.0
            for k in op.input_keys
                complexity = get_complexity(branch[k])
                full_input_complexity += complexity
                weight = get_key_fill_weight(branch, k)
                explained_input_complexity += weight * complexity
            end
            new_weight = explained_input_complexity/full_input_complexity
            for k in op.output_keys
                if get_key_fill_weight(branch, k) < new_weight
                    branch.fill_percentages[k] = new_weight
                    push!(updated_weights, k)
                    if new_weight == 1.0
                        branch.known_fields[k] = branch.unknown_fields[k]
                        delete!(branch.unknown_fields, k)
                    end
                end
            end
        end
    end
end

function get_key_fill_weight(branch, key)::Float64
    if haskey(branch.known_fields, key)
        return 1.0
    elseif haskey(branch.fill_percentages, key)
        return branch.fill_percentages[key]
    elseif !isnothing(branch.parent)
        return get_key_fill_weight(branch.parent, key)
    else
        error("Missing fill weight value")
    end
end

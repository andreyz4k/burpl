
function extract_solution(branch, target_keys)
    operations_map = Dict()
    for op in branch.operations
        if all(!haskey(branch.unknown_fields, key) for key in op.input_keys)
            for key in op.output_keys
                operations_map[key] = op
            end
        end
    end
    needed_keys = Set(target_keys)
    result = []
    used_ops = Set()
    while !isempty(needed_keys)
        key = pop!(needed_keys)
        if !haskey(operations_map, key)
            continue
        end
        op = operations_map[key]
        if !in(op, used_ops)
            push!(result, operations_map[key])
            push!(used_ops, op)
            union!(needed_keys, op.input_keys)
        end
    end
    return reverse(result)
end

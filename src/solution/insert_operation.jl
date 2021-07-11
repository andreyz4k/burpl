
using ..Operations: Operation, Project

function move_to_next_block(solution::Solution)::Solution
    blocks = copy(solution.blocks)
    new_block = Block()

    unused_projected_fields = Set(f for f in solution.unused_fields if startswith(f, "projected|"))
    used_projected_fields = Set()

    prev_block_ops = []
    for operation in reverse(blocks[end].operations)
        if all(in(key, unused_projected_fields) for key in operation.output_keys)
            setdiff!(unused_projected_fields, operation.output_keys)
            union!(unused_projected_fields, (f for f in operation.input_keys if startswith(f, "projected|")))
            continue
        end
        union!(used_projected_fields, (f for f in operation.input_keys if startswith(f, "projected|")))
        setdiff!(used_projected_fields, operation.output_keys)
        if any(
            in(key, solution.unfilled_fields) || in(key, solution.transformed_fields) for key in operation.input_keys
        )
            push!(new_block.operations, operation)
        else
            push!(prev_block_ops, operation)
        end
    end

    blocks[end] = Block(reverse(prev_block_ops))

    last_block_output = [
        blocks[end](
            filter(
                keyval -> !in(keyval[1], solution.unfilled_fields) && !in(keyval[1], solution.transformed_fields),
                task,
            ),
        ) for task in solution.taskdata
    ]

    taskdata =
        [merge(task_data, block_output) for (task_data, block_output) in zip(solution.taskdata, last_block_output)]

    field_info = solution.field_info
    for op in blocks[end].operations
        for key in op.output_keys
            if !haskey(field_info, key)
                input_field_info = [field_info[k] for k in op.input_keys if haskey(field_info, k)]
                i = argmin([length(info.derived_from) for info in input_field_info])
                dependent_key = input_field_info[i].derived_from
                for task in taskdata
                    if haskey(task, key) && _is_valid_value(task[key])
                        field_info[key] = FieldInfo(
                            task[key],
                            dependent_key,
                            vcat([info.precursor_types for info in input_field_info]...),
                            [(field_info[k].previous_fields for k in op.input_keys)..., [key]],
                        )
                        break
                    end
                end
            end
        end
    end

    if length(blocks) > 1
        if isempty(used_projected_fields)
            blocks[end-1] = Block(vcat(blocks[end-1].operations[1:end-1], blocks[end].operations))
            pop!(blocks)
        else
            old_project_op = blocks[end-1].operations[end]
            blocks[end-1] = Block(blocks[end-1].operations[1:end-1])
            push!(
                blocks[end-1].operations,
                Project(
                    old_project_op.operations,
                    Set(replace(key, "projected|" => "") for key in used_projected_fields),
                ),
            )
        end
    end

    reverse!(new_block.operations)
    unused_fields = solution.unused_fields

    if !isempty(solution.unfilled_fields) && !isempty(new_block.operations)
        project_op = Project(new_block.operations, union(solution.unfilled_fields, solution.transformed_fields))
        push!(blocks[end].operations, project_op)

        input_field_info = [field_info[key] for key in project_op.input_keys if haskey(field_info, key)]
        i = argmin([length(info.derived_from) for info in input_field_info])
        dependent_key = input_field_info[i].derived_from

        projected_output = [project_op(block_output) for block_output in last_block_output]

        taskdata = [filter(keyval -> !startswith(keyval[1], "projected|"), task_data) for task_data in taskdata]
        unused_fields = filter(key -> !startswith(key, "projected|"), solution.unused_fields)
        field_info = filter(keyval -> !startswith(keyval[1], "|projected"), field_info)

        for key in project_op.output_keys
            for (observed_task, output) in zip(taskdata, projected_output)
                if haskey(output, key)
                    observed_task[key] = output[key]
                    push!(unused_fields, key)
                    if !haskey(field_info, key) && _is_valid_value(output[key])
                        field_info[key] = FieldInfo(
                            output[key],
                            dependent_key,
                            vcat([info.precursor_types for info in input_field_info]...),
                            [(field_info[k].previous_fields for k in project_op.input_keys)..., [key]],
                        )
                    end
                end
            end
        end
    end

    if isempty(solution.unfilled_fields)
        for (task, block_output) in zip(taskdata, last_block_output)
            task["projected|output"] = block_output["output"]
        end
    end

    if !isempty(new_block.operations)
        push!(blocks, new_block)
    end

    Solution(
        taskdata,
        field_info,
        blocks,
        solution.unfilled_fields,
        solution.filled_fields,
        solution.transformed_fields,
        unused_fields,
        solution.used_fields,
        solution.input_transformed_fields,
        solution.complexity_score,
        solution.inp_val_hashes,
        solution.out_val_hashes,
    )
end

function mark_dependent_sections(blocks, fill_fields, unf_fields, field_info, unfilled_fields, transformed_fields)
    source_key = nothing
    for block in blocks[end:-1:1], oper in block.operations[end:-1:1]
        fields_in_chain = filter(k -> in(k, fill_fields), oper.output_keys)
        if isnothing(source_key) && !isempty(fields_in_chain)
            setdiff!(fill_fields, fields_in_chain)
            union!(fill_fields, oper.input_keys)
            if hasfield(typeof(oper), :aux_keys)
                setdiff!(fill_fields, oper.aux_keys)
            end
            if length(fill_fields) == 1
                for k in oper.output_keys
                    if all(in(field_info[k].type, field_info[needed_key].precursor_types) for needed_key in unf_fields)
                        source_key = k
                        break
                    end
                end
            end
        end
        if any(in(k, unf_fields) for k in oper.output_keys)
            union!(unf_fields, filter(k -> in(k, unfilled_fields) || in(k, transformed_fields), oper.input_keys))
        end
    end
    if !isnothing(source_key)
        for needed_key in unf_fields
            if length(source_key) > length(field_info[needed_key].derived_from)
                field_info[needed_key] = FieldInfo(
                    field_info[needed_key].type,
                    source_key,
                    field_info[needed_key].precursor_types,
                    field_info[needed_key].previous_fields,
                )
            end
        end
    end
end

function mark_used_fields_for_output(
    key,
    i,
    blocks,
    output_chain,
    unfilled_fields,
    filled_fields,
    transformed_fields,
    unused_fields,
    used_fields,
    input_transformed_fields,
    field_info,
)
    for op in blocks[end].operations[i:end]
        if any(in(k, output_chain) for k in op.output_keys)
            unf_fields = filter(k -> in(k, unfilled_fields) || in(k, transformed_fields), op.input_keys)
            fill_fields = filter(
                k ->
                    !in(k, unfilled_fields) &&
                        !in(k, transformed_fields) &&
                        (hasfield(typeof(op), :aux_keys) ? !in(k, op.aux_keys) : true),
                op.input_keys,
            )
            if isempty(unf_fields)
                for k in op.output_keys
                    if in(k, unfilled_fields)
                        delete!(unfilled_fields, k)
                        push!(filled_fields, k)
                    end
                    if in(k, transformed_fields)
                        delete!(transformed_fields, k)
                        push!(filled_fields, k)
                    end
                    push!(used_fields, k)
                    if haskey(field_info, k)
                        input_field_info = [field_info[k] for k in op.input_keys if haskey(field_info, k)]
                        field_info[k] = FieldInfo(
                            field_info[k].type,
                            field_info[k].derived_from,
                            unique([
                                vcat([info.precursor_types for info in input_field_info]...)...,
                                field_info[k].type,
                            ]),
                            union([(field_info[pk].previous_fields for pk in op.input_keys)..., [k]]...),
                        )
                    end
                end
            elseif !isempty(fill_fields)
                mark_dependent_sections(
                    blocks,
                    fill_fields,
                    unf_fields,
                    field_info,
                    unfilled_fields,
                    transformed_fields,
                )
            end
        end
    end

    delete!(unused_fields, key)

    inp_keys = [key]
    in_ops = vcat(blocks[end].operations[i:-1:1], (block.operations[end:-1:1] for block in blocks[end-1:-1:1])...)
    for op in in_ops
        if any(in(k, inp_keys) for k in op.output_keys)
            for k in op.input_keys
                push!(used_fields, k)
                if in(k, input_transformed_fields)
                    delete!(input_transformed_fields, k)
                end
            end
            append!(inp_keys, op.input_keys)
        end
    end
end

using ..Operations: wrap_operation, get_unfilled_inputs

function mark_used_fields_for_input(blocks, unfilled_fields, filled_fields, transformed_fields, field_info, taskdata)
    for block in blocks, op in block.operations
        still_unfilled_keys = get_unfilled_inputs(op, taskdata)
        for key in op.input_keys
            if in(key, unfilled_fields) && !in(key, still_unfilled_keys)
                delete!(unfilled_fields, key)
            end
        end
        if all(!in(k, unfilled_fields) && !in(k, transformed_fields) for k in op.input_keys)
            for k in op.output_keys
                if in(k, unfilled_fields)
                    delete!(unfilled_fields, k)
                    push!(filled_fields, k)
                end
                if in(k, transformed_fields)
                    delete!(transformed_fields, k)
                    push!(filled_fields, k)
                end
                if haskey(field_info, k)
                    input_field_info = [field_info[k] for k in op.input_keys if haskey(field_info, k)]
                    field_info[k] = FieldInfo(
                        field_info[k].type,
                        field_info[k].derived_from,
                        unique([vcat([info.precursor_types for info in input_field_info]...)..., field_info[k].type]),
                        union([(field_info[pk].previous_fields for pk in op.input_keys)..., [k]]...),
                    )
                end
            end
        end
    end
end

function mark_used_fields(
    key,
    i,
    blocks,
    unfilled_fields,
    filled_fields,
    transformed_fields,
    unused_fields,
    used_fields,
    input_transformed_fields,
    taskdata,
    field_info,
)
    output_chain = ["output"]
    for block in blocks[end:-1:1], op in block.operations[end:-1:1]
        if any(in(k, output_chain) for k in op.output_keys)
            append!(output_chain, op.input_keys)
        end
    end
    if in(key, output_chain)
        mark_used_fields_for_output(
            key,
            i,
            blocks,
            output_chain,
            unfilled_fields,
            filled_fields,
            transformed_fields,
            unused_fields,
            used_fields,
            input_transformed_fields,
            field_info,
        )
    else
        mark_used_fields_for_input(blocks, unfilled_fields, filled_fields, transformed_fields, field_info, taskdata)
    end
end

function get_source_key(operation, source_key)
    source_key
end


function prune_unnneeded_operations(key, blocks, transformed_fields, unfilled_fields, taskdata, field_info)
    target_output_fields = [key]
    output_ops = []
    for operation in blocks[end].operations[end:-1:1]
        if any(in(key, operation.output_keys) for key in target_output_fields)
            for k in operation.input_keys
                # TODO: check if used_fields are no longer used and delete them safely
                if in(k, transformed_fields)
                    push!(target_output_fields, k)
                    delete!(transformed_fields, k)
                    for task_data in taskdata
                        delete!(task_data, k)
                    end
                    delete!(field_info, k)
                elseif in(k, unfilled_fields)
                    delete!(unfilled_fields, k)
                    for task_data in taskdata
                        delete!(task_data, k)
                    end
                    delete!(field_info, k)
                end
            end
        else
            push!(output_ops, operation)
        end
    end
    blocks[end] = Block(reverse(output_ops))
end


function insert_operation(
    solution::Solution,
    operation::Operation;
    added_complexity::Float64 = 0.0,
    reversed_op = nothing,
    no_wrap = false,
)::Solution
    try
        unfilled_fields = copy(solution.unfilled_fields)
        transformed_fields = copy(solution.transformed_fields)
        filled_fields = copy(solution.filled_fields)
        unused_fields = copy(solution.unused_fields)
        used_fields = copy(solution.used_fields)
        input_transformed_fields = copy(solution.input_transformed_fields)

        field_info = copy(solution.field_info)
        blocks = copy(solution.blocks)

        transformed_filled_fields = filter(k -> in(k, transformed_fields), operation.output_keys)

        if !isempty(transformed_filled_fields)
            taskdata = [copy(task) for task in solution.taskdata]
            for key in transformed_filled_fields
                prune_unnneeded_operations(key, blocks, transformed_fields, unfilled_fields, taskdata, field_info)
            end
        else
            taskdata = solution.taskdata
        end

        op = isnothing(reversed_op) ? operation : reversed_op

        taskdata = [op(task) for task in taskdata]

        if isnothing(reversed_op) && !no_wrap
            taskdata, operation = wrap_operation(taskdata, operation)
        end

        blocks[end], index = insert_operation(blocks, operation)

        input_field_info = [field_info[key] for key in operation.input_keys if haskey(field_info, key)]
        output_field_info = [field_info[key] for key in operation.output_keys if haskey(field_info, key)]

        new_input_fields = filter(
            key ->
                !in(key, unused_fields) &&
                    !in(key, used_fields) &&
                    !in(key, input_transformed_fields) &&
                    !in(key, unfilled_fields) &&
                    !in(key, transformed_fields) &&
                    !in(key, filled_fields),
            operation.input_keys,
        )
        union!(unfilled_fields, new_input_fields)

        if !isempty(new_input_fields)
            if !isempty(output_field_info)
                i = argmax([length(info.derived_from) for info in output_field_info])
                out_dependent_key = output_field_info[i].derived_from
            else
                i = argmax([length(info.derived_from) for info in input_field_info])
                out_dependent_key = input_field_info[i].derived_from
            end
            for key in new_input_fields
                for task in taskdata
                    if haskey(task, key) && _is_valid_value(task[key])
                        field_info[key] = FieldInfo(
                            task[key],
                            get_source_key(operation, out_dependent_key),
                            vcat([info.precursor_types for info in output_field_info]...),
                            [Set()],
                        )
                        break
                    end
                end
            end
        end

        for key in setdiff(operation.input_keys, new_input_fields)
            if in(key, unused_fields)
                delete!(unused_fields, key)
                push!(input_transformed_fields, key)
            end
        end

        if !isempty(input_field_info)
            i = argmax([length(info.derived_from) for info in input_field_info])
            inp_dependent_key = input_field_info[i].derived_from
        end

        fields_to_mark = []

        for key in operation.output_keys
            if in(key, unfilled_fields)
                delete!(unfilled_fields, key)
                push!(transformed_fields, key)
                if isempty(new_input_fields)
                    push!(fields_to_mark, key)
                end
            elseif in(key, transformed_fields)
                if isempty(new_input_fields)
                    push!(fields_to_mark, key)
                end
            else
                push!(unused_fields, key)
                for task in taskdata
                    if haskey(task, key) && _is_valid_value(task[key])
                        field_info[key] = FieldInfo(
                            task[key],
                            inp_dependent_key,
                            vcat([info.precursor_types for info in input_field_info]...),
                            [(field_info[k].previous_fields for k in operation.input_keys)..., [key]],
                        )
                        break
                    end
                end
            end
        end

        for key in fields_to_mark
            mark_used_fields(
                key,
                index,
                blocks,
                unfilled_fields,
                filled_fields,
                transformed_fields,
                unused_fields,
                used_fields,
                input_transformed_fields,
                taskdata,
                field_info,
            )
        end

        new_solution = Solution(
            taskdata,
            field_info,
            blocks,
            unfilled_fields,
            filled_fields,
            transformed_fields,
            unused_fields,
            used_fields,
            input_transformed_fields,
            solution.complexity_score + added_complexity,
            solution.inp_val_hashes,
            solution.out_val_hashes,
        )
        if !isempty(filter(k -> !startswith(k, "projected|"), fields_to_mark))
            return move_to_next_block(new_solution)
        end
        return new_solution
    catch
        @info(operation)
        @info(solution)
        rethrow()
    end
end

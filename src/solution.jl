export Solutions
module Solutions

using ..Operations: Operation, Project, get_sorting_keys

struct Block
    operations::Array{Operation}
end

Block() = Block([])

function insert_operation(blocks::AbstractVector{Block}, operation::Operation)::Tuple{Block,Int}
    filled_keys =
        reduce(union, [op.output_keys for block in blocks[1:end-1] for op in block.operations], init = Set(["input"]))
    last_block_outputs = reduce(
        merge,
        [Dict(key => index for key in op.output_keys) for (index, op) in enumerate(blocks[end].operations)],
        init = Dict(),
    )
    # last_block_outputs = reduce(union, [op.output_keys for op in blocks[end].operations], init=Set{String}())
    needed_fields = setdiff(operation.input_keys, filled_keys)
    union!(needed_fields, filter(k -> haskey(last_block_outputs, k), operation.output_keys))
    operations = copy(blocks[end].operations)
    for (index, op) in enumerate(operations)
        if isempty(needed_fields) || any(in(key, op.input_keys) for key in operation.output_keys)
            insert!(operations, index, operation)
            return Block(operations), index
        end
        setdiff!(needed_fields, filter(key -> last_block_outputs[key] == index, op.output_keys))
    end
    push!(operations, operation)
    Block(operations), length(operations)
end

Base.show(io::IO, b::Block) = print(io, "Block([\n", (vcat((["\t\t", op, ",\n"] for op in b.operations)...))..., "\t])")

using ..Taskdata: TaskData, persist_data

function (block::Block)(observed_data::TaskData)::TaskData
    for op in block.operations
        try
            observed_data = op(observed_data)
        catch e
            if isa(e, KeyError)
                @info("missing key $e")
            else
                rethrow()
            end
        end
    end
    observed_data
end

Base.:(==)(a::Block, b::Block) = a.operations == b.operations

Base.hash(b::Block, h::UInt64) = hash(b.operations, h)

struct FieldInfo
    type::Type
    derived_from::String
    precursor_types::Vector{Type}
    previous_fields::Set{String}
    FieldInfo(type::Type, derived_from::String, precursor_types, previous_fields) =
        new(type, derived_from, precursor_types, Set(previous_fields))
end

Base.show(io::IO, f::FieldInfo) =
    print(io, "FieldInfo(", f.type, ", \"", f.derived_from, "\", ", f.precursor_types, ", ", f.previous_fields, ")")

using ..PatternMatching: Matcher, unwrap_matcher

_get_type(::T) where {T} = T
_get_type(val::Matcher) = _get_type(unwrap_matcher(val)[1])
function _get_type(val::Dict)
    key, value = first(val)
    Dict{_get_type(key),_get_type(value)}
end
_get_type(val::Vector) = Vector{_get_type(val[1])}

function FieldInfo(value, derived_from, precursor_types, previous_fields)
    type = _get_type(value)
    return FieldInfo(type, derived_from, unique([precursor_types..., type]), union(previous_fields...))
end

_is_valid_value(val) = true
_is_valid_value(val::Union{Array,Dict}) = !isempty(val)

struct Solution
    taskdata::TaskData
    field_info::Dict{String,FieldInfo}
    blocks::Vector{Block}
    unfilled_fields::Set{String}
    filled_fields::Set{String}
    transformed_fields::Set{String}
    unused_fields::Set{String}
    used_fields::Set{String}
    input_transformed_fields::Set{String}
    complexity_score::Float64
    score::Int
    inp_val_hashes::Vector{Set{UInt64}}
    out_val_hashes::Vector{Set{UInt64}}
    function Solution(
        taskdata,
        field_info,
        blocks,
        unfilled_fields,
        filled_fields,
        transformed_fields,
        unused_fields,
        used_fields,
        input_transformed_fields,
        complexity_score::Float64,
    )
        inp_val_hashes = fill(Set{UInt64}(), length(taskdata["input"]))
        out_val_hashes = fill(Set{UInt64}(), length(taskdata["input"]))
        for (key, values) in taskdata
            for (i, value) in enumerate(values)
                if in(key, transformed_fields) || in(key, filled_fields) || in(key, unfilled_fields)
                    push!(out_val_hashes[i], hash(value))
                end
                if in(key, unused_fields) || in(key, used_fields) || in(key, input_transformed_fields)
                    push!(inp_val_hashes[i], hash(value))
                end
            end
        end
        new(
            taskdata,
            field_info,
            blocks,
            unfilled_fields,
            filled_fields,
            transformed_fields,
            unused_fields,
            used_fields,
            input_transformed_fields,
            complexity_score,
            get_score(taskdata, complexity_score),
            inp_val_hashes,
            out_val_hashes,
        )
    end
end

function Solution(task_info)
    Solution(
        TaskData(
            Dict("input" => [task["input"] for task in task_info], "output" => [task["output"] for task in task_info]),
            Dict{String,Any}(),
            Set{String}(),
        ),
        Dict(
            "input" => FieldInfo(task_info[1]["input"], "input", [], [["input"]]),
            "output" => FieldInfo(task_info[1]["output"], "input", [], [Set()]),
        ),
        [Block()],
        Set(["output"]),
        Set(),
        Set(),
        Set(["input"]),
        Set(),
        Set(),
        0.0,
    )
end

persist_updates(solution::Solution) = Solution(
    persist_data(solution.taskdata),
    solution.field_info,
    solution.blocks,
    solution.unfilled_fields,
    solution.filled_fields,
    solution.transformed_fields,
    solution.unused_fields,
    solution.used_fields,
    solution.input_transformed_fields,
    solution.complexity_score,
)


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

    last_block_output = blocks[end](
        filter(
            keyval -> !in(keyval[1], solution.unfilled_fields) && !in(keyval[1], solution.transformed_fields),
            solution.taskdata,
        ),
    )

    taskdata = merge(solution.taskdata, last_block_output)

    field_info = solution.field_info
    for op in blocks[end].operations
        for key in op.output_keys
            if !haskey(field_info, key)
                input_field_info = [field_info[k] for k in op.input_keys if haskey(field_info, k)]
                i = argmin([length(info.derived_from) for info in input_field_info])
                dependent_key = input_field_info[i].derived_from
                for val in taskdata[key]
                    if !ismissing(val) && _is_valid_value(val)
                        field_info[key] = FieldInfo(
                            val,
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

        projected_output = project_op(last_block_output)

        taskdata = filter(keyval -> !startswith(keyval[1], "projected|"), taskdata)
        unused_fields = filter(key -> !startswith(key, "projected|"), solution.unused_fields)
        field_info = filter(keyval -> !startswith(keyval[1], "|projected"), field_info)

        for key in project_op.output_keys
            if haskey(projected_output, key)
                taskdata[key] = projected_output[key]
                push!(unused_fields, key)
                if !haskey(field_info, key)
                    for val in projected_output[key]
                        if _is_valid_value(val)
                            field_info[key] = FieldInfo(
                                val,
                                dependent_key,
                                vcat([info.precursor_types for info in input_field_info]...),
                                [(field_info[k].previous_fields for k in project_op.input_keys)..., [key]],
                            )
                            break
                        end
                    end
                end
            end
        end
    end

    if isempty(solution.unfilled_fields)
        taskdata["projected|output"] = last_block_output["output"]
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


function insert_operation(
    solution::Solution,
    operation::Operation;
    added_complexity::Float64 = 0.0,
    reversed_op = nothing,
    no_wrap = false,
)::Solution
    try
        op = isnothing(reversed_op) ? operation : reversed_op

        taskdata = op(solution.taskdata)

        if isnothing(reversed_op) && !no_wrap
            taskdata, operation = wrap_operation(taskdata, operation)
        end

        unfilled_fields = copy(solution.unfilled_fields)
        transformed_fields = copy(solution.transformed_fields)
        filled_fields = copy(solution.filled_fields)
        unused_fields = copy(solution.unused_fields)
        used_fields = copy(solution.used_fields)
        input_transformed_fields = copy(solution.input_transformed_fields)

        blocks = copy(solution.blocks)
        blocks[end], index = insert_operation(blocks, operation)

        field_info = copy(solution.field_info)
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
                for val in taskdata[key]
                    if !ismissing(val) && _is_valid_value(val)
                        field_info[key] = FieldInfo(
                            val,
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
            else
                push!(unused_fields, key)
                if haskey(taskdata, key)
                    for val in taskdata[key]
                        if !ismissing(val) && _is_valid_value(val)
                            field_info[key] = FieldInfo(
                                val,
                                inp_dependent_key,
                                vcat([info.precursor_types for info in input_field_info]...),
                                [(field_info[k].previous_fields for k in operation.input_keys)..., [key]],
                            )
                            break
                        end
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

Base.show(io::IO, s::Solution) = print(
    io,
    "Solution(",
    s.score,
    ", ",
    get_unmatched_complexity_score(s),
    ", ",
    "unfilled: ",
    s.unfilled_fields,
    "\n\t",
    "transformed: ",
    s.transformed_fields,
    "\n\t",
    "filled: ",
    s.filled_fields,
    "\n\t",
    "unused: ",
    s.unused_fields,
    "\n\t",
    "used: ",
    s.used_fields,
    "\n\t",
    "input transformed: ",
    s.input_transformed_fields,
    "\n\t[\n\t",
    s.blocks...,
    "\n\t]\n\t",
    "Dict(\n",
    (vcat(
        (
            ["\t\t", keyval, ",\n"] for keyval in s.field_info if haskey(s.taskdata, keyval[1]) && (
                in(keyval[1], s.unfilled_fields) ||
                in(keyval[1], s.unused_fields) ||
                in(keyval[1], s.input_transformed_fields) ||
                in(keyval[1], s.used_fields)
            )
        )...,
    ))...,
    "\t)\n\t",
    s.taskdata,
    "\n)",
)

function (solution::Solution)(input_grids::Vector{Array{Int,2}})::Vector{Array{Int,2}}
    observed_data = TaskData(Dict{String,Vector}("input" => input_grids), Dict{String,Vector}(), Set())
    for block in solution.blocks
        observed_data = block(observed_data)
    end
    get(observed_data, "output", fill(Array{Int}(undef, 0, 0), length(input_grids)))
end

Base.:(==)(a::Solution, b::Solution)::Bool = a.blocks == b.blocks

Base.hash(s::Solution, h::UInt64) = hash(s.blocks, h)

function check_task(solution::Solution, input_grids::Vector{Array{Int,2}}, targets::Vector{Array{Int,2}})
    out = solution(input_grids)
    compare_grids(targets, out)
end

function compare_grids(targets::Vector, outputs::Vector)
    result = 0
    for (target, output) in zip(targets, outputs)
        if size(target) != size(output)
            result += reduce(*, size(target))
        else
            result += sum(output .!= target)
        end
    end
    return result
end

function get_score(taskdata::TaskData, complexity_score)::Int
    score = compare_grids(
        taskdata["output"],
        get(taskdata, "projected|output", fill(Array{Int}(undef, 0, 0), length(taskdata["output"]))),
    )
    # if complexity_score > 100
    #     score += floor(complexity_score)
    # end
    score
end

using ..Complexity: get_complexity

function get_unmatched_complexity_score(solution::Solution)
    unmatched_data_score = sum(
        Float64[
            sum(Float64[get_complexity(value) for value in values]) for
            (key, values) in solution.taskdata if in(key, solution.unfilled_fields)
        ],
    )
    transformed_data_score = sum(
        Float64[
            sum(Float64[get_complexity(value) / 10 for value in values]) for
            (key, values) in solution.taskdata if in(key, solution.transformed_fields)
        ],
    )
    unused_data_score = sum(
        Float64[
            sum(
                Float64[
                    startswith(key, "projected|") ? get_complexity(value) / 6 : get_complexity(value) for
                    value in values
                ],
            ) for (key, values) in solution.taskdata if in(key, solution.unused_fields)
        ],
    )

    inp_transformed_data_score = sum(
        Float64[
            sum(Float64[get_complexity(value) / 3 for value in values]) for
            (key, values) in solution.taskdata if in(key, solution.input_transformed_fields)
        ],
    )
    return (unmatched_data_score +
            # transformed_data_score +
            unused_data_score +
            inp_transformed_data_score +
            solution.complexity_score) / length(solution.taskdata["input"])
end

end

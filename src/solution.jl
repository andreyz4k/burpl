export Solutions
module Solutions

export validate_solution

using ..Operations:Operation,Project,get_sorting_keys

struct Block
    operations::Array{Operation}
end

Block() = Block([])

function insert_operation(blocks::AbstractVector{Block}, operation::Operation)::Tuple{Block,Int}
    filled_keys = reduce(union, [op.output_keys for block in blocks[1:end - 1] for op in block.operations], init=Set(["input"]))
    last_block_outputs = reduce(union, [op.output_keys for op in blocks[end].operations], init=Set{String}())
    needed_fields = setdiff(operation.input_keys, filled_keys)
    union!(needed_fields, filter(k -> in(k, last_block_outputs), operation.output_keys))
    operations = copy(blocks[end].operations)
    for (index, op) in enumerate(operations)
        if isempty(needed_fields) || any(in(key, op.input_keys) for key in operation.output_keys)
            insert!(operations, index, operation)
            return Block(operations), index
        end
        setdiff!(needed_fields, op.output_keys)
    end
    push!(operations, operation)
    Block(operations), length(operations)
end

Base.show(io::IO, b::Block) =
    print(io, "Block([\n", (vcat((["\t\t", op,",\n"] for op in b.operations)...))..., "\t])")

function (block::Block)(observed_data::Dict)::Dict
    for op in block.operations
        try
            observed_data = op(observed_data)
        catch KeyError
        end
    end
    observed_data
end

Base.:(==)(a::Block, b::Block) = a.operations == b.operations

Base.hash(b::Block, h::UInt64) = hash(b.operations, h)

struct UnfilledFields
    # TODO: fill
end

struct Solution
    taskdata::Array{Dict{String,Any}}
    blocks::Array{Block}
    unfilled_fields::Set{String}
    filled_fields::Set{String}
    transformed_fields::Set{String}
    unused_fields::Set{String}
    used_fields::Set{String}
    input_transformed_fields::Set{String}
    complexity_score::Float64
    generality::Float64
    score::Int
    inp_val_hashes::Array{Set{UInt64}}
    out_val_hashes::Array{Set{UInt64}}
    function Solution(taskdata, blocks, unfilled_fields,
             filled_fields, transformed_fields, unused_fields, used_fields,
             input_transformed_fields, complexity_score::Float64, generality)
        inp_val_hashes = Set{UInt64}[]
        out_val_hashes = Set{UInt64}[]
        for task_data in taskdata
            inp_vals = Set{UInt64}()
            out_vals = Set{UInt64}()
            for (key, value) in task_data
                if in(key, transformed_fields) || in(key, filled_fields) ||  in(key, unfilled_fields)
                    push!(out_vals, hash(value))
                end
                if in(key, unused_fields) || in(key, used_fields) || in(key, input_transformed_fields)
                    push!(inp_vals, hash(value))
                end
            end
            push!(inp_val_hashes, inp_vals)
            push!(out_val_hashes, out_vals)
        end
        new(taskdata, blocks,
            unfilled_fields, filled_fields, transformed_fields,
            unused_fields, used_fields, input_transformed_fields,
            complexity_score, generality, get_score(taskdata, complexity_score),
            inp_val_hashes, out_val_hashes)
    end
end

Solution(taskdata) = Solution(
    taskdata,
    [Block()],
    Set(["output"]),
    Set(),
    Set(),
    Set(["input"]),
    Set(),
    Set(),
    0.0,
    0.0
)

function move_to_next_block(solution::Solution)::Solution
    blocks = copy(solution.blocks)
    new_block = Block()

    unused_projected_fields = Set(f for f in solution.unused_fields if startswith(f, "projected|"))
    used_projected_fields = Set()

    prev_block_ops = []
    for operation in reverse(blocks[end].operations)

        if any(in(key, unused_projected_fields) for key in operation.output_keys)
            setdiff!(unused_projected_fields, operation.output_keys)
            union!(unused_projected_fields, (f for f in operation.input_keys if startswith(f, "projected|")))
            continue
        end
        union!(used_projected_fields, (f for f in operation.input_keys if startswith(f, "projected|")))
        setdiff!(used_projected_fields, operation.output_keys)
        if any(in(key, solution.unfilled_fields) || in(key, solution.transformed_fields) for key in operation.input_keys)
            push!(new_block.operations, operation)
        else
            push!(prev_block_ops, operation)
        end
    end

    blocks[end] = Block(reverse(prev_block_ops))

    last_block_output = [
        blocks[end](filter(keyval -> !in(keyval[1], solution.unfilled_fields) &&
                            !in(keyval[1], solution.transformed_fields), task))
        for task in
        solution.taskdata
    ]

    if length(blocks) > 1
        if isempty(used_projected_fields)
            blocks[end - 1] = Block(vcat(blocks[end - 1].operations[1:end - 1], blocks[end].operations))
            pop!(blocks)
        else
            old_project_op = blocks[end - 1].operations[end]
            blocks[end - 1] = Block(blocks[end - 1].operations[1:end - 1])
            push!(blocks[end - 1].operations, Project(old_project_op.operations,
                                                    Set(replace(key, "projected|" => "") for key in used_projected_fields)))
        end
    end

    reverse!(new_block.operations)
    unused_fields = solution.unused_fields
    taskdata = [merge(task_data, block_output) for (task_data, block_output) in zip(solution.taskdata, last_block_output)]

    if !isempty(solution.unfilled_fields) && !isempty(new_block.operations)
        project_op = Project(new_block.operations, union(solution.unfilled_fields, solution.transformed_fields))
        push!(blocks[end].operations, project_op)

        projected_output = [
            project_op(block_output)
            for block_output
            in last_block_output
        ]

        taskdata = [
            filter(keyval -> !startswith(keyval[1], "projected|"), task_data)
            for task_data in solution.taskdata
        ]
        unused_fields = filter(key -> !startswith(key, "projected|"), solution.unused_fields)

        for (observed_task, output) in zip(taskdata, projected_output)
            for key in project_op.output_keys
                if haskey(output, key)
                    observed_task[key] = output[key]
                    push!(unused_fields, key)
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
        blocks,
        solution.unfilled_fields,
        solution.filled_fields,
        solution.transformed_fields,
        unused_fields,
        solution.used_fields,
        solution.input_transformed_fields,
        solution.complexity_score,
        solution.generality
    )
end

using ..PatternMatching:Matcher

function mark_used_fields(key, i, blocks, unfilled_fields, filled_fields, transformed_fields, unused_fields, used_fields, input_transformed_fields, taskdata)
    output_chain = ["output"]
    for block in blocks[end:-1:1]
        for op in block.operations[end:-1:1]
            if any(in(k, output_chain) for k in op.output_keys)
                append!(output_chain, op.input_keys)
            end
        end
    end
    if in(key, output_chain)
        for op in blocks[end].operations[i:end]
            if any(in(k, output_chain) for k in op.output_keys) && all(!in(k, unfilled_fields) && !in(k, transformed_fields) for k in op.input_keys)
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
                end
            end
        end

        delete!(unused_fields, key)

        inp_keys = [key]
        in_ops = vcat(blocks[end].operations[i:-1:1], (block.operations[end:-1:1] for block in blocks[end - 1:-1:1])...)
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
    else
        for field in unfilled_fields
            if !in(field, output_chain)
                if all(!isa(get(task, field, nothing), Matcher) for task in taskdata)
                    delete!(unfilled_fields, field)
                end
            end
        end
        for block in blocks
            for op in block.operations
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
                    end
                end
            end
        end
    end
end

_check_matcher(::Any) = false
_check_matcher(::Matcher) = true
_check_matcher(value::AbstractDict) = any(_check_matcher(v) for v in values(value))
_check_matcher(value::AbstractVector) = any(_check_matcher(v) for v in value)

function insert_operation(solution::Solution, operation::Operation; added_complexity::Float64=0.0, reversed_op=nothing)::Solution
    blocks = copy(solution.blocks)
    blocks[end], index = insert_operation(blocks, operation)
    op = isnothing(reversed_op) ? operation : reversed_op

    taskdata = [
        op(task)
        for task
        in solution.taskdata
    ]
    unfilled_fields = copy(solution.unfilled_fields)
    transformed_fields = copy(solution.transformed_fields)
    filled_fields = copy(solution.filled_fields)
    unused_fields = copy(solution.unused_fields)
    used_fields = copy(solution.used_fields)
    input_transformed_fields = copy(solution.input_transformed_fields)

    need_next_block = false

    new_input_fields = filter(key -> !in(key, unused_fields) && !in(key, used_fields) && !in(key, input_transformed_fields), operation.input_keys)
    union!(unfilled_fields, new_input_fields)

    for key in setdiff(operation.input_keys, new_input_fields)
        if in(key, unused_fields)
            delete!(unused_fields, key)
            push!(input_transformed_fields, key)
        end
    end

    for key in operation.output_keys
        if in(key, unfilled_fields)
            delete!(unfilled_fields, key)
            push!(transformed_fields, key)
            if isempty(new_input_fields)
                need_next_block = true
                mark_used_fields(key, index, blocks, unfilled_fields, filled_fields, transformed_fields, unused_fields, used_fields, input_transformed_fields, taskdata)
            end
        else
            push!(unused_fields, key)
            if any(_check_matcher(get(task, key, nothing)) for task in taskdata)
                push!(unfilled_fields, key)
            end
        end
    end

    new_solution = Solution(
        taskdata,
        blocks,
        unfilled_fields,
        filled_fields,
        transformed_fields,
        unused_fields,
        used_fields,
        input_transformed_fields,
        solution.complexity_score + added_complexity,
        solution.generality + (hasfield(typeof(operation), :generability) ? operation.generability : 0.0),
    )
    if need_next_block
        return move_to_next_block(new_solution)
    end
    new_solution
end

Base.show(io::IO, s::Solution) =
    print(io, "Solution(", s.score, ", ",
          get_unmatched_complexity_score(s), ", ", s.generality, ", ",
          "unfilled: ", s.unfilled_fields, "\n\t",
          "transformed: ", s.transformed_fields, "\n\t",
          "filled: ", s.filled_fields, "\n\t",
          "unused: ", s.unused_fields, "\n\t",
          "used: ", s.used_fields, "\n\t",
          "input transformed: ", s.input_transformed_fields, "\n\t[\n\t",
          s.blocks..., "\n\t]\n\t",
          [
              filter(keyval -> in(keyval[1], s.unfilled_fields) || in(keyval[1], s.unused_fields),
                     task_data)
              for task_data in s.taskdata
          ],
          "\n)")

function (solution::Solution)(input_grid::Array{Int,2})::Array{Int,2}
    observed_data = Dict{String,Any}("input" => input_grid)
    for block in solution.blocks
        observed_data = block(observed_data)
    end
    get(observed_data, "output", Array{Int}(undef, 0, 0))
end

Base.:(==)(a::Solution, b::Solution)::Bool = a.blocks == b.blocks

Base.hash(s::Solution, h::UInt64) = hash(s.blocks, h)

function check_task(solution::Solution, input_grid::Array{Int,2}, target::Array{Int,2})
    out = solution(input_grid)
    compare_grids(target, out)
end

function compare_grids(target::Array{Int,2}, output::Array{Int,2})
    if size(target) != size(output)
        return reduce(*, size(target))
    end
    sum(output .!= target)
end

function get_score(taskdata, complexity_score)::Int
    score = sum(compare_grids(task["output"], get(task, "projected|output", Array{Int}(undef, 0, 0)))
                for task
                in taskdata)
    # if complexity_score > 100
    #     score += floor(complexity_score)
    # end
    score
end

using ..Complexity:get_complexity

function get_unmatched_complexity_score(solution::Solution)
    unmatched_data_score = [
        sum(
            Float64[get_complexity(value) for (key, value) in task_data if in(key, solution.unfilled_fields)],
        ) for task_data in solution.taskdata
    ]
    transformed_data_score = [
        sum(
            Float64[get_complexity(value) / 10 for (key, value) in task_data if in(key, solution.transformed_fields)],
        ) for task_data in solution.taskdata
    ]
    unused_data_score = [
        sum(
            Float64[startswith(key, "projected|") ? get_complexity(value) / 3  : get_complexity(value)
            for (key, value) in task_data if in(key, solution.unused_fields)],
        ) for task_data in solution.taskdata
    ]
    inp_transformed_data_score = [
        sum(
            Float64[get_complexity(value) / 3
            for (key, value) in task_data if in(key, solution.input_transformed_fields)],
        ) for task_data in solution.taskdata
    ]
    return (
            sum(unmatched_data_score) +
            # sum(transformed_data_score) +
            sum(unused_data_score) +
            sum(inp_transformed_data_score) +
            solution.complexity_score
    ) / length(solution.taskdata)
end

function validate_solution(solution, taskdata)
    sum(check_task(solution, task["input"], task["output"]) for task in taskdata)
end

end

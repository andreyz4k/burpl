include("operation.jl")
include("perceptors.jl")
include("complexity.jl")
module SolutionOps
export generate_solution
export validate_solution

using ..Operations: Operation

struct Block
    operations::Array{Operation}
end

Block() = Block([])

function insert_operation(block::Block, operation::Operation, from_start=true)::Tuple{Block,Int}
    operations = copy(block.operations)
    if from_start
        needed_fields = Set(operation.input_keys)
    else
        needed_fields = Set(operation.output_keys)
        if isempty(needed_fields)
            push!(operations, operation)
            return Block(operations), length(operations)
        end
    end
    for index in length(operations):-1:1
        op = operations[index]
        if from_start
            if any(in(key, needed_fields) for key in op.output_keys)
                insert!(operations, index, operation)
                return Block(operations), index
            end
        else
            needed_fields -= Set(op.input_keys)
            if isempty(needed_fields)
                insert!(operations, index, operation)
                return Block(operations), index
            end
        end
    end
    insert!(operations, 1, operation)
    Block(operations), 1
end

Base.show(io::IO, b::Block) =
    print(io, "Block([\n\t\t", b.operations..., "\n\t])")

function (block::Block)(input_grid::Array{Int,2}, output_grid::Array{Int,2},
             observed_data::Dict)::Tuple{Array{Int,2},Dict}
    for op in block.operations
        output_grid, observed_data = op(input_grid, output_grid, observed_data)
    end
    output_grid, observed_data
end

==(a::Block, b::Block) = a.operations == b.operations

hash(b::Block, h) = hash(b.operations, h)

struct UnfilledFields
    # TODO: fill
end

struct Solution
    taskdata::Array
    blocks::Array{Block}
    projected_grid::Array{Array{Int,2}}
    observed_data::Array{Dict}
    unfilled_fields::Set
    filled_fields::Set
    transformed_fields::Set
    unused_fields::Set
    used_fields::Set
    complexity_score::Int
    score::Int
    Solution(taskdata, blocks, projected_grid, observed_data, unfilled_fields,
             filled_fields, transformed_fields, unused_fields, used_fields,
             complexity_score) = new(taskdata, blocks, projected_grid,
             observed_data, unfilled_fields, filled_fields, transformed_fields,
             unused_fields, used_fields, complexity_score,
             get_score(taskdata, projected_grid, complexity_score))
end

Solution(taskdata) = Solution(
    taskdata,
    [Block()],
    [Array{Int}(undef, 0, 0) for _ in 1:length(taskdata)],
    [Dict() for _ in 1:length(taskdata)],
    Set(),
    Set(),
    Set(),
    Set(),
    Set(),
    0
)

function move_to_next_block(blocks)
    # TODO: fill
    blocks
end

function Solution(solution::Solution, operation; for_output=false, reversed_op=nothing)
    blocks = copy(solution.blocks)
    blocks[end], index = insert_operation(blocks[end], operation, !for_output)

    op = for_output ? reversed_op : operation
    grid_key = for_output ? "output" : "input"

    outputs = [
        op(task[grid_key], projected_grid, task_data)
        for (task, projected_grid, task_data)
        in zip(solution.taskdata, solution.projected_grid, solution.observed_data)
    ]
    projected_grid = [item[1] for item in outputs]
    observed_data = [item[2] for item in outputs]
    unfilled_fields = copy(solution.unfilled_fields)
    transformed_fields = copy(solution.transformed_fields)
    unused_fields = copy(solution.unused_fields)
    used_fields = copy(solution.used_fields)
    filled_fields = copy(solution.filled_fields)
    if for_output
        union!(unfilled_fields, key for key in operation.input_keys if !in(key, solution.filled_fields))
        for key in operation.output_keys
            if in(key, unfilled_fields)
                delete!(unfilled_fields, key)
                push!(transformed_fields, key)
            end
        end
    else
        need_next_block = false
        union!(unused_fields, operation.output_keys)
        for key in operation.input_keys
            if in(key, unused_fields)
                delete!(unused_fields, key)
                push!(used_fields, key)
            end
        end
        for op in blocks[end].operations[index:end]
            if all(!in(key, unfilled_fields) && !in(key, transformed_fields)
                    for key in op.input_keys)
                for key in op.output_keys
                    if in(key, unfilled_fields)
                        need_next_block = true
                        delete!(unfilled_fields, key)
                        push!(filled_fields, key)
                        if in(key, unused_fields)
                            delete!(unused_fields, key)
                            push!(used_fields, key)
                        end
                    end
                    if in(key, transformed_fields)
                        delete!(transformed_fields, key)
                        push!(filled_fields, key)
                    end
                end
            end
        end
        if need_next_block
            blocks = move_to_next_block(blocks)
        end
    end

    Solution(
        solution.taskdata,
        blocks,
        projected_grid,
        observed_data,
        unfilled_fields,
        filled_fields,
        transformed_fields,
        unused_fields,
        used_fields,
        solution.complexity_score,
    )
end

Base.show(io::IO, s::Solution) =
    print(io, "Solution(", s.score, ", ",
          get_unmatched_complexity_score(s), ", ",
          s.unfilled_fields, "\n\t",
          s.transformed_fields, "\n\t",
          s.filled_fields, "\n\t",
          s.unused_fields, "\n\t",
          s.used_fields, "\n\t[\n\t",
          s.blocks..., "\n\t]\n\t",
          [Dict(key => value for (key, value) in pairs(task_data)
            if (in(key, s.unfilled_fields) || in(key, s.unused_fields)))
            for task_data in s.observed_data],
          "\n)")

function (solution::Solution)(input_grid::Array{Int,2})::Array{Int,2}
    output_grid = Array{Int}(undef, 0, 0)
    observed_data = Dict()
    for block in solution.blocks
        output_grid, observed_data = block(input_grid, output_grid, observed_data)
    end
    output_grid
end

==(a::Solution, b::Solution)::Bool = a.blocks == b.blocks

hash(s::Solution, h::Int) = hash(s.blocks, h)

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

function get_score(taskdata, projected_grids, complexity_score)::Int
    score = sum(compare_grids(task["output"], projected_grid)
                for (task, projected_grid)
                in zip(taskdata, projected_grids))
    if complexity_score > 100
        score += complexity_score
    end
    score
end

using ..Complexity:get_complexity

function get_unmatched_complexity_score(solution::Solution)
    unmatched_data_score = [
        reduce(
            +,
            (get_complexity(value) for (key, value) in pairs(task_data) if in(key, solution.unfilled_fields)),
            init=0.0
        ) for task_data in solution.observed_data
    ]
    unused_data_score = [
        reduce(
            +,
            (startswith(key, "projected|") ? get_complexity(value) / 3  : get_complexity(value)
            for (key, value) in pairs(task_data) if in(key, solution.unused_fields)),
            init=0.0
        ) for task_data in solution.observed_data
    ]
    return (
            sum(unmatched_data_score) +
            sum(unused_data_score) +
            solution.complexity_score
    ) / length(solution.observed_data)
end

function match_fields(solution::Solution)
    return []
end

import ..Perceptors

function get_next_perceptors(solution::Solution, source, grids)
    res = reduce(vcat, (Perceptors.create(op_class, solution, source, grids)
                 for op_class in Perceptors.classes), init=[])
    println(res)
    return res
end


function get_new_output_perceptors(solution::Solution)::Array{Tuple{Int,Solution}}
    output = []
    for (priority, perceptor) in get_next_perceptors(solution, "output",
            [task["output"] for task in solution.taskdata])
        operation = perceptor.from_abstract
        new_solution = Solution(solution, operation, for_output=true,
                                reversed_op=perceptor.to_abstract)
        println(new_solution)
        for matched_solution in match_fields(new_solution)
            push!(output,
                  (priority * get_unmatched_complexity_score(matched_solution) *
                   matched_solution.score, matched_solution))
        end
    end
    output
end


function get_new_solutions(solution::Solution, debug::Bool)::Array{Tuple{Int,Solution}}
    new_solutions = get_new_output_perceptors(solution)
    # TODO: add additional methods
    if debug
        println(new_solutions)
        readline(stdin)
    end
    return new_solutions
end

function check_border(solution::Solution, border::Set)
    # TODO: fill
    return true
end

function update_border!(border::Set, solution::Solution)
    # TODO: fill
end

using DataStructures

function generate_solution(taskdata::Array, fname::AbstractString, debug::Bool)
    println(fname)
    init_solution = Solution(taskdata)
    queue = PriorityQueue()
    visited = Set()
    real_visited = 0
    border = Set()
    enqueue!(queue, (init_solution, 0), 0)
    best_solution = init_solution
    while !isempty(queue)
        (solution, i), pr = peek(queue)
        dequeue!(queue)
        if in(solution, visited)
            continue
        end
        push!(visited, solution)
        if !check_border(solution, border)
            continue
        end
        real_visited += 1
        update_border!(border, solution)
        println((real_visited, length(border), length(queue)))
        println((pr, i, solution))
        new_solutions = get_new_solutions(solution, debug)
        for (priority, new_solution) in new_solutions
            if in(new_solution, visited) || !check_border(new_solution, border)
                continue
            end
            new_error = new_solution.score
            if new_error > solution.score
                continue
            end
            if new_error == 0
                println((real_visited, length(queue)))
                return new_solution
            end
            i += 1
            if new_error < best_solution.score
                best_solution = new_solution
            end
            enqueue!(queue, (new_solution, i - 1), priority * (i + 1) / 2)
        end
        if real_visited > 1000
            break
        end
    end
    println((real_visited, length(queue)))
    return best_solution
end

function validate_solution(solution, taskdata)
    sum(check_task(solution, task["input"], task["output"]) for task in taskdata)
end
end
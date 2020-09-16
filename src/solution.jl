export SolutionOps
module SolutionOps
export generate_solution
export validate_solution

using ..Operations:Operation,Project,get_sorting_keys

struct Block
    operations::Array{Operation}
end

Block() = Block([])

function insert_operation(block::Block, operation::Operation, ::Val{true})::Tuple{Block,Int}
    operations = copy(block.operations)
    needed_fields = Set(operation.input_keys)
    for index in length(operations):-1:1
        op = operations[index]
        if any(in(key, needed_fields) for key in op.output_keys)
            insert!(operations, index + 1, operation)
            return Block(operations), index + 1
        end
    end
    insert!(operations, 1, operation)
    Block(operations), 1
end

function insert_operation(block::Block, operation::Operation, ::Val{false})::Tuple{Block,Int}
    operations = copy(block.operations)
    needed_fields = Set(get_sorting_keys(operation))
    if isempty(needed_fields)
        push!(operations, operation)
        return Block(operations), length(operations)
    end
    for index in length(operations):-1:1
        op = operations[index]
        setdiff!(needed_fields, op.input_keys)
        if isempty(needed_fields)
            insert!(operations, index, operation)
            return Block(operations), index
        end
    end
    insert!(operations, 1, operation)
    Block(operations), 1
end

Base.show(io::IO, b::Block) =
    print(io, "Block([\n", (vcat((["\t\t", op,",\n"] for op in b.operations)...))..., "\t])")

function (block::Block)(input_grid::Array{Int,2}, output_grid::Array{Int,2},
             observed_data::Dict)::Tuple{Array{Int,2},Dict}
    for op in block.operations
        output_grid, observed_data = op(input_grid, output_grid, observed_data)
    end
    output_grid, observed_data
end

Base.:(==)(a::Block, b::Block) = a.operations == b.operations

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
    complexity_score::Float64
    score::Int
    Solution(taskdata, blocks, projected_grid, observed_data, unfilled_fields,
             filled_fields, transformed_fields, unused_fields, used_fields,
             complexity_score::Float64) = new(taskdata, blocks, projected_grid,
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
        blocks[end](task["input"], projected_grid,
                    filter(keyval -> !in(keyval[1], solution.unfilled_fields) &&
                            !in(keyval[1], solution.transformed_fields), task_data))
        for (task, projected_grid, task_data) in
        zip(solution.taskdata, solution.projected_grid, solution.observed_data)
    ]
    projected_grid = [item[1] for item in last_block_output]

    if length(blocks) > 1
        if isempty(used_projected_fields)
            blocks[end - 1] = Block(vcat(blocks[end - 1].operations[1:end - 1], blocks[end].operations))
            pop!(blocks)
        else
            blocks[end - 1] = Block(blocks[end - 1].operations[1:end - 1])
            push!(blocks[end - 1].operations, Project(old_project_op.operations,
                                                    Set(replace(key, "projected|" => "") for key in used_projected_fields)))
        end
    end

    reverse!(new_block.operations)
    observed_data = solution.observed_data
    unused_fields = solution.unused_fields

    if !isempty(solution.unfilled_fields) && !isempty(new_block.operations)
        project_op = Project(new_block.operations, union(solution.unfilled_fields, solution.transformed_fields))
        push!(blocks[end].operations, project_op)

        projected_output = [
            project_op(task["input"], block_output[1], block_output[2])
            for (task, block_output)
            in zip(solution.taskdata, last_block_output)
        ]
        projected_grid = [item[1] for item in projected_output]

        observed_data = [
            filter(keyval -> !startswith(keyval[1], "projected|"), task_data)
            for task_data in solution.observed_data
        ]
        unused_fields = filter(key -> !startswith(key, "projected|"), solution.unused_fields)

        for (observed_task, output) in zip(observed_data, projected_output)
            for key in project_op.output_keys
                if haskey(output[2], key)
                    observed_task[key] = output[2][key]
                    push!(unused_fields, key)
                end
            end
        end
    end

    if !isempty(new_block.operations)
        push!(blocks, new_block)
    end

    Solution(
        solution.taskdata,
        blocks,
        projected_grid,
        observed_data,
        solution.unfilled_fields,
        solution.filled_fields,
        solution.transformed_fields,
        unused_fields,
        solution.used_fields,
        solution.complexity_score
    )
end

function Solution(solution::Solution, operation::Operation; added_complexity::Float64=0.0)
    blocks = copy(solution.blocks)
    blocks[end], index = insert_operation(blocks[end], operation, Val(true))

    outputs = [
        operation(task["input"], projected_grid, task_data)
        for (task, projected_grid, task_data)
        in zip(solution.taskdata, solution.projected_grid, solution.observed_data)
    ]
    observed_data = [item[2] for item in outputs]
    unfilled_fields = copy(solution.unfilled_fields)
    transformed_fields = copy(solution.transformed_fields)
    unused_fields = copy(solution.unused_fields)
    used_fields = copy(solution.used_fields)
    filled_fields = copy(solution.filled_fields)

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
    new_solution = Solution(
        solution.taskdata,
        blocks,
        solution.projected_grid,
        observed_data,
        unfilled_fields,
        filled_fields,
        transformed_fields,
        unused_fields,
        used_fields,
        solution.complexity_score + added_complexity,
    )
    if need_next_block
        return move_to_next_block(new_solution)
    end
    new_solution
end

function Solution(solution::Solution, operation::Operation, reversed_op::Operation)
    blocks = copy(solution.blocks)
    blocks[end], index = insert_operation(blocks[end], operation, Val(false))

    outputs = [
        reversed_op(task["output"], projected_grid, task_data)
        for (task, projected_grid, task_data)
        in zip(solution.taskdata, solution.projected_grid, solution.observed_data)
    ]
    observed_data = [item[2] for item in outputs]
    unfilled_fields = copy(solution.unfilled_fields)
    transformed_fields = copy(solution.transformed_fields)

    union!(unfilled_fields, key for key in operation.input_keys if !in(key, solution.filled_fields))
    for key in operation.output_keys
        if in(key, unfilled_fields)
            delete!(unfilled_fields, key)
            push!(transformed_fields, key)
        end
    end

    Solution(
        solution.taskdata,
        blocks,
        solution.projected_grid,
        observed_data,
        unfilled_fields,
        solution.filled_fields,
        transformed_fields,
        solution.unused_fields,
        solution.used_fields,
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
          [
              filter(keyval -> in(keyval[1], s.unfilled_fields) || in(keyval[1], s.unused_fields),
                     task_data)
              for task_data in s.observed_data
          ],
          "\n)")

function (solution::Solution)(input_grid::Array{Int,2})::Array{Int,2}
    output_grid = Array{Int}(undef, 0, 0)
    observed_data = Dict()
    for block in solution.blocks
        output_grid, observed_data = block(input_grid, output_grid, observed_data)
    end
    output_grid
end

Base.:(==)(a::Solution, b::Solution)::Bool = a.blocks == b.blocks

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
        sum(
            Float64[get_complexity(value) for (key, value) in task_data if in(key, solution.unfilled_fields)],
        ) for task_data in solution.observed_data
    ]
    unused_data_score = [
        sum(
            Float64[startswith(key, "projected|") ? get_complexity(value) / 3  : get_complexity(value)
            for (key, value) in task_data if in(key, solution.unused_fields)],
        ) for task_data in solution.observed_data
    ]
    return (
            sum(unmatched_data_score) +
            sum(unused_data_score) +
            solution.complexity_score
    ) / length(solution.observed_data)
end

function compare_values(val1, val2)
    if isnothing(val1) || val1 == val2
        return val2
    end
    if isa(val1, Dict) && isa(val2, Dict)
        if !issetequal(keys(val1), keys(val2))
            return nothing
        end
        match = Dict()
        for key in val1
            m = compare_values(val1[key], val2[key])
            if isnothing(m)
                return nothing
            end
            match[key] = m
        end
        return match
    end
    # if isinstance(val2, Matcher)
    #     return val2.match(val1)
    # end
    # if isinstance(val1, Matcher)
    #     return val1.match(val2)
    # end
    return nothing
end

function find_const(solution::Solution, key::String)::Array
    result = nothing
    for task_data in solution.observed_data
        if !haskey(task_data, key)
            continue
        end
        possible_value = compare_values(result, task_data[key])
        if isnothing(possible_value)
            return []
        end
        result = possible_value
    end
    # if isa(result, Matcher)
    #     return result.get_values()
    # end
    return [result]
end

using ..DataTransformers:SetConst

function check_const_values(key::String, solution::Solution)
    new_solutions = []
    const_options = find_const(solution, key)
    for value in const_options
        transformer = SetConst(key, value)
        new_solution = Solution(solution, transformer,
                                added_complexity=transformer.complexity)
        push!(new_solutions, new_solution)
    end
    return new_solutions
end

function exact_match_fields(solution::Solution)
    for key in solution.unfilled_fields
        new_solutions = check_const_values(key, solution)
        find_matches_funcs = [
            # TODO: fill
            # find_exactly_matched_fields,
            # find_proportionate_matched_fields,
            # find_shifted_matched_fields,
            # find_proportionate_by_key_matched_fields,
            # find_shifted_by_key_matched_fields
        ]
        for func in find_matches_funcs
            if lenght(new_solutions) == 1
                break
            end
            new_solutions += func(key, solution)
        end
        if !isempty(new_solutions)
            return reduce(
                vcat,
                (exact_match_fields(new_solution) for new_solution in new_solutions),
                init=[]
            )
        end
    end
    return [solution]
end

function find_mapped_fields(key, solution)
    # TODO: fill
    return []
end

function match_fields(solution::Solution)
    out = []
    for new_solution in exact_match_fields(solution)
        mapped_solutions = Set([new_solution])
        for key in new_solution.unfilled_fields
            next_solutions = Set()
            for cur_solution in mapped_solutions
                union!(next_solutions, find_mapped_fields(key, cur_solution))
            end
            union!(mapped_solutions, next_solutions)
        end
        for mapped_solution in mapped_solutions
            push!(out, mapped_solution)
        end
    end
    return out
end

import ..Perceptors

function get_next_perceptors(solution::Solution, source, grids)
    res = reduce(vcat, (Perceptors.create(op_class, solution, source, grids)
                 for op_class in Perceptors.classes), init=[])
    return res
end


function get_new_output_perceptors(solution::Solution)::Array{Tuple{Float64,Solution}}
    output = []
    for (priority, perceptor) in get_next_perceptors(solution, "output",
            [task["output"] for task in solution.taskdata])
        new_solution = Solution(solution, perceptor.from_abstract, perceptor.to_abstract)
        for matched_solution in match_fields(new_solution)
            println(matched_solution)
            push!(output,
                  (priority * get_unmatched_complexity_score(matched_solution) *
                   matched_solution.score, matched_solution))
        end
    end
    output
end


function get_new_input_perceptors(solution::Solution)::Array{Tuple{Float64,Solution}}
    # unfilled_data_types = Set()
    # for key_info in solution.unfilled_fields.params.values()
    #     unfilled_data_types.update(key_info.precursor_data_types)
    #     unfilled_data_types.add(key_info.data_type)
    # end
    output = []
    for (priority, perceptor_pair) in get_next_perceptors(solution, "input",
                                                   [task["input"] for task in solution.taskdata])
        perceptor = perceptor_pair.to_abstract
        new_solution = Solution(solution, perceptor)
        # for abs_key in perceptor.output_keys
        #     if new_solution.get_key_data_type(abs_key) in unfilled_data_types
        #         priority /= 2
        #         break
        #     end
        # else
        #     priority *= 2
        # end

        for matched_solution in match_fields(new_solution)
            push!(output,
                  (priority * get_unmatched_complexity_score(matched_solution) *
                   matched_solution.score, matched_solution))
        end
    end
    output
end


import ..Abstractors

function get_next_operations(solution, key)
    res = reduce(vcat, (Abstractors.create(op_class, solution, key)
                        for op_class in Abstractors.classes), init=[])
    return res
end


function get_new_solutions_for_unfilled_key(solution::Solution, key::String)
    output = []
    for (priority, abstractor) in get_next_operations(solution, key)
        # precursors = []
        # for key in abstractor.detailed_keys
        #     precursors.append(new_solution.unfilled_fields[key])
        # end

        new_solution = Solution(solution, abstractor.from_abstract, abstractor.to_abstract)

        # for abs_key in abstractor.abs_keys
        #     new_solution.unfilled_fields[abs_key].precursor_data_types = {
        #         data_type
        #         for precursor in precursors
        #         for data_type in {precursor.data_type}.union(precursor.precursor_data_types)
        #     }
        # end

        for matched_solution in match_fields(new_solution)
            push!(output,
                  (priority * get_unmatched_complexity_score(matched_solution) *
                   matched_solution.score, matched_solution))
        end
    end
    output
end


function get_new_solutions(solution::Solution, debug::Bool)::Array{Tuple{Float64,Solution}}
    new_solutions = get_new_output_perceptors(solution)
    for key in solution.unfilled_fields
        append!(new_solutions, get_new_solutions_for_unfilled_key(solution, key))
    end
    if !isempty(solution.unfilled_fields)
        append!(new_solutions, get_new_input_perceptors(solution))
    end
    # TODO: add additional methods
    if debug
        println(new_solutions)
        readline(stdin)
    end
    return new_solutions
end


function is_subsolution(parent_sol::Solution, child_sol::Solution)::Bool
    equals = true
    for (child_task_data, parent_task_data) in zip(child_sol.observed_data, parent_sol.observed_data)
        for (key, value) in child_task_data
            if !haskey(parent_task_data, key) || value != parent_task_data[key]
                return false
            end
        end
        if !issetequal(keys(child_task_data), keys(parent_task_data))
            equals = false
        end
    end
    if equals && parent_sol != child_sol
        return false
    end
    return true
end

check_border(solution::Solution, border::Set)::Bool =
    all(!is_subsolution(border_sol, solution) for border_sol in border)

function update_border!(border::Set, solution::Solution)
    obsolete = []
    for border_sol in border
        if is_subsolution(solution, border_sol)
            push!(obsolete, border_sol)
        end
    end
    setdiff!(border, obsolete)
    push!(border, solution)
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
            println((priority, new_error))
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
    # println(visited)
    return best_solution
end

function validate_solution(solution, taskdata)
    sum(check_task(solution, task["input"], task["output"]) for task in taskdata)
end
end

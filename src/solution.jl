module SolutionOps
export generate_solution
export validate_solution

struct Block
    operations::Array
end

Block() = Block([])

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

mutable struct Solution
    taskdata::Array
    blocks::Array{Block}
    projected_grid::Array{Array{Int,2}}
    observed_data::Array{Dict}
    unfilled_fields::Dict
    filled_fields::Set
    transformed_fields::Set
    unused_fields::Set
    used_fields::Set
    score::Union{Nothing,Int}
    complexity_score::Int
end

Solution(taskdata) = Solution(
    taskdata,
    [Block()],
    [Array{Int}(undef, 0, 0) for _ in 1:length(taskdata)],
    [Dict() for _ in 1:length(taskdata)],
    Dict(),
    Set(),
    Set(),
    Set(),
    Set(),
    nothing,
    0
)

function Solution(solution::Solution, operation; for_output=false, reversed_op=nothing)
    # TODO: fill
    solution
end

Base.show(io::IO, s::Solution) =
    print(io, "Solution(", get_score(s), ", ",
          get_unmatched_complexity_score(s), ", ",
          keys(s.unfilled_fields), "\n\t",
          s.transformed_fields, "\n\t",
          s.filled_fields, "\n\t",
          s.unused_fields, "\n\t",
          s.used_fields, "\n\t[\n\t",
          s.blocks..., "\n\t]\n\t",
          [Dict(key => value for (key, value) in pairs(task_data)
            if in(key, s.unfilled_fields) || in(key, s.unused_fields))
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

function get_score(solution::Solution)
    if isa(solution.score, Int)
        return solution.score
    end
    score = sum(compare_grids(task["output"], projected_grid)
                for (task, projected_grid)
                in zip(solution.taskdata, solution.projected_grid))
    if solution.complexity_score > 100
        score += solution.complexity_score
    end
    solution.score = score
end

function get_unmatched_complexity_score(solution::Solution)
    # TODO: fill
    0
end

function match_fields(solution::Solution)
    return []
end

include("perceptors.jl")

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
        for matched_solution in match_fields(new_solution)
            push!(output,
                  (priority * get_unmatched_complexity_score(matched_solution) *
                   get_score(matched_solution), matched_solution))
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
            new_error = get_score(new_solution)
            if new_error > get_score(solution)
                continue
            end
            if new_error == 0
                println((real_visited, length(queue)))
                return new_solution
            end
            i += 1
            if new_error < get_score(best_solution)
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
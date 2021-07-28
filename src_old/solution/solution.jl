export Solutions
module Solutions

export validate_solution

include("block.jl")
include("field_info.jl")

using ..Taskdata: get_value_hash

mutable struct Solution
    taskdata::Vector{TaskData}
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
    hash_value::Union{UInt64,Nothing}
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
        inp_val_hashes,
        out_val_hashes,
    )
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
            nothing,
        )
    end
end

function Solution(taskdata)
    Solution(
        [
            persist_data(
                TaskData(Dict{String,Any}(), task, Set{String}(), Dict{String,Float64}(), Dict{String,UInt64}()),
            ) for task in taskdata
        ],
        Dict(
            "input" => FieldInfo(taskdata[1]["input"], "input", [], [["input"]]),
            "output" => FieldInfo(taskdata[1]["output"], "input", [], [Set()]),
        ),
        [Block()],
        Set(["output"]),
        Set(),
        Set(),
        Set(["input"]),
        Set(),
        Set(),
        0.0,
        [],
        [],
    )
end

function persist_updates(solution::Solution)
    taskdata = [persist_data(task) for task in solution.taskdata]
    inp_val_hashes = Set{UInt64}[]
    out_val_hashes = Set{UInt64}[]
    for task_data in taskdata
        inp_vals = Set{UInt64}()
        out_vals = Set{UInt64}()
        for key in keys(task_data)
            if in(key, solution.transformed_fields) ||
               in(key, solution.filled_fields) ||
               in(key, solution.unfilled_fields)
                push!(out_vals, get_value_hash(task_data, key))
            end
            if in(key, solution.unused_fields) ||
               in(key, solution.used_fields) ||
               in(key, solution.input_transformed_fields)
                push!(inp_vals, get_value_hash(task_data, key))
            end
        end
        push!(inp_val_hashes, inp_vals)
        push!(out_val_hashes, out_vals)
    end
    Solution(
        taskdata,
        solution.field_info,
        solution.blocks,
        solution.unfilled_fields,
        solution.filled_fields,
        solution.transformed_fields,
        solution.unused_fields,
        solution.used_fields,
        solution.input_transformed_fields,
        solution.complexity_score,
        inp_val_hashes,
        out_val_hashes,
    )
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
            ["\t\t", keyval, ",\n"] for keyval in s.field_info if haskey(s.taskdata[1], keyval[1]) && (
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

function (solution::Solution)(input_grid::Array{Int,2})::Array{Int,2}
    observed_data = TaskData(
        Dict{String,Any}("input" => input_grid),
        Dict{String,Any}(),
        Set(),
        Dict{String,Float64}(),
        Dict{String,UInt64}(),
    )
    for block in solution.blocks
        observed_data = block(observed_data)
    end
    get(observed_data, "output", Array{Int}(undef, 0, 0))
end

Base.:(==)(a::Solution, b::Solution)::Bool = a.blocks == b.blocks

function Base.hash(s::Solution, h::UInt64)
    if isnothing(s.hash_value)
        s.hash_value = hash(s.blocks)
    end
    s.hash_value - 3h
end

include("insert_operation.jl")


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
    score =
        sum(compare_grids(task["output"], get(task, "projected|output", Array{Int}(undef, 0, 0))) for task in taskdata)
    # if complexity_score > 100
    #     score += floor(complexity_score)
    # end
    score
end

using ..Taskdata: get_value_complexity

function get_unmatched_complexity_score(solution::Solution)
    unmatched_data_score = sum(
        (
            get_value_complexity(task_data, key) for task_data in solution.taskdata for
            key in keys(task_data) if in(key, solution.unfilled_fields)
        ),
        init = 0.0,
    )
    transformed_data_score = sum(
        (
            get_value_complexity(task_data, key) / 10 for task_data in solution.taskdata for
            key in keys(task_data) if in(key, solution.transformed_fields)
        ),
        init = 0.0,
    )
    unused_data_score = sum(
        (
            startswith(key, "projected|") ? get_value_complexity(task_data, key) / 6 :
            get_value_complexity(task_data, key) for task_data in solution.taskdata for
            key in keys(task_data) if in(key, solution.unused_fields)
        ),
        init = 0.0,
    )
    inp_transformed_data_score = sum(
        (
            get_value_complexity(task_data, key) / 3 for task_data in solution.taskdata for
            key in keys(task_data) if in(key, solution.input_transformed_fields)
        ),
        init = 0.0,
    )
    return (unmatched_data_score +
            transformed_data_score +
            unused_data_score +
            inp_transformed_data_score +
            solution.complexity_score) / length(solution.taskdata)
end

function validate_solution(solution, taskdata)
    sum(check_task(solution, task["input"], task["output"]) for task in taskdata)
end

end

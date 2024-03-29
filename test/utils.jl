
using .Solutions: Solution, Block, FieldInfo, insert_operation, get_unmatched_complexity_score, persist_updates
using .Operations: Operation, Project
using .DataTransformers: match_fields
using .Abstractors: create
using .Taskdata: TaskData
using Test: AbstractTestSet, Error, Fail, DefaultTestSet

import Test: record, finish

make_sample_taskdata(len) = fill(Dict("input" => Array{Int}(undef, 0, 0), "output" => Array{Int}(undef, 0, 0)), len)

struct FakeOperation <: Operation
    input_keys::Any
    output_keys::Any
    aux_keys::Any
end

(op::FakeOperation)(task_data) = task_data

make_taskdata(tasks) = [make_taskdata(task) for task in tasks]

make_taskdata(task::Dict) = TaskData(Dict{String,Any}(), task, Set(), Dict{String,Float64}(), Dict{String,UInt64}())

make_field_info(taskdata) = Dict(key => FieldInfo(val, "input", [], [Set()]) for (key, val) in taskdata[1])

function make_dummy_solution(data, unfilled = [])
    unused = Set(filter(k -> !in(k, unfilled) && k != "input" && k != "output", keys(data[1])))
    taskdata = make_taskdata([
        merge(Dict("input" => Array{Int}(undef, 0, 0), "output" => Array{Int}(undef, 0, 0)), task) for task in data
    ])
    Solution(
        taskdata,
        make_field_info(taskdata),
        [Block([FakeOperation(unfilled, ["output"], [])])],
        Set(unfilled),
        Set(),
        Set(),
        unused,
        Set(),
        Set(),
        0.0,
        [],
        [],
    )
end

function _compare_operations(expected, solutions)
    for solution in solutions
        ops = filtered_ops(solution)
        @test any(ops == bl for bl in expected)
        filter!(bl -> bl != ops, expected)
    end
    @test isempty(expected)
end

filtered_taskdata(solution) = [
    Dict(filter(keyval -> keyval[1] != "input" && keyval[1] != "output" && keyval[1] != "projected|output", task))
    for task in solution.taskdata
]

filtered_ops(solution) =
    filter(op -> !isa(op, FakeOperation) && !isa(op, Project), vcat((block.operations for block in solution.blocks)...))

function create_solution(taskdata, operations)
    solution = Solution(taskdata)
    for (op_class, key, to_abs) in operations
        abstractor = create(op_class, solution, key)[1][2]
        if to_abs
            new_solution = insert_operation(solution, abstractor.to_abstract)
        else
            new_solution = insert_operation(solution, abstractor.from_abstract, reversed_op = abstractor.to_abstract)
        end
        solution = sort(match_fields(new_solution), by = sol -> get_unmatched_complexity_score(sol))[1]
        solution = persist_updates(solution)
    end
    solution
end

using .FindSolution: validate_results

function test_solution(solution, test_data)
    answer = [solution(task["input"]) for task in test_data]
    validate_results(test_data, [answer])
end



mutable struct LogFilterTestSet{T<:AbstractTestSet} <: AbstractTestSet
    wrapped::T
    description::String
    log_file::String
    LogFilterTestSet{T}(desc, log_file) where {T} = new(T(desc), desc, log_file)
end
LogFilterTestSet(desc; log_file = nothing, wrap = DefaultTestSet) = LogFilterTestSet{wrap}(desc, log_file)


record(ts::LogFilterTestSet, t) = record(ts.wrapped, t)

using Serialization: serialize, deserialize
using Base: @logmsg

function record(ts::LogFilterTestSet, t::Union{Fail,Error})
    println("\n=====================================================")
    printstyled(ts.description, "\n"; color = :white)
    printstyled("Captured log output:\n"; color = :white)
    open(ts.log_file) do io
        while !eof(io)
            log_args = deserialize(io)
            @logmsg(
                log_args.level,
                log_args.message,
                log_args.kwargs...,
                _module = log_args._module,
                _group = log_args.group,
                _id = log_args.id,
                _file = log_args.file,
                _line = log_args.line
            )
        end
    end
    record(ts.wrapped, t)
end


function finish(ts::LogFilterTestSet)
    finish(ts.wrapped)
end

function dump_log_event(io, log_args)
    serialize(io, log_args)
end

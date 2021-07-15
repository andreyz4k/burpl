
using .Solutions: Solution, Block, FieldInfo, insert_operation, get_unmatched_complexity_score, persist_updates
using .Operations: Operation, Project
using .DataTransformers: match_fields
using .Abstractors: create
using .Taskdata: TaskData
using .ObjectPrior: Object
using .PatternMatching: Either, ObjectShape
using burpl: OInt

function Object(shape::Matrix{Int64}, position::Tuple{Int64,Int64})
    new_shape = similar(shape, OInt)
    for x = 1:size(shape)[1], y = 1:size(shape)[2]
        new_shape[x, y] = OInt(shape[x, y])
    end
    Object(new_shape, (OInt(position[1]), OInt(position[2])))
end

function Object(shape::Vector{Int64}, position::Tuple{Int64,Int64})
    Object([OInt(v) for v in shape], (OInt(position[1]), OInt(position[2])))
end


make_sample_taskdata(len) = fill(Dict("input" => Array{OInt}(undef, 0, 0), "output" => Array{OInt}(undef, 0, 0)), len)

struct FakeOperation <: Operation
    input_keys::Any
    output_keys::Any
    aux_keys::Any
end

(op::FakeOperation)(task_data) = task_data

make_taskdata(tasks) = [make_taskdata(task) for task in tasks]

_wrap_ints(v::Any) = v
_wrap_ints(v::Int64) = OInt(v)
_wrap_ints(val::Tuple) = tuple([_wrap_ints(v) for v in val]...)
_wrap_ints(val::Vector) = [_wrap_ints(v) for v in val]
function _wrap_ints(val::Matrix)
    res = similar(val, OInt)
    for x in 1:size(val)[1], y in 1:size(val)[2]
        res[x, y] = _wrap_ints(val[x, y])
    end
    res
end
_wrap_ints(val::Dict) = Dict(_wrap_ints(kv[1]) => _wrap_ints(kv[2]) for kv in val)
_wrap_ints(val::Either) = Either([Option(_wrap_ints(option.value), option.option_hash) for option in val.options])
_wrap_ints(val::ObjectShape) = ObjectShape(_wrap_ints(val.object))

make_taskdata(task::Dict) = TaskData(Dict{String,Any}(), _wrap_ints(task), Set(), Dict{String,Float64}(), Dict{String,UInt64}())

make_field_info(taskdata) = Dict(key => FieldInfo(val, "input", [], [Set()]) for (key, val) in taskdata[1])

function make_dummy_solution(data, unfilled = [])
    unused = Set(filter(k -> !in(k, unfilled) && k != "input" && k != "output", keys(data[1])))
    taskdata = make_taskdata([
        merge(Dict("input" => Array{OInt}(undef, 0, 0), "output" => Array{OInt}(undef, 0, 0)), task) for task in data
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

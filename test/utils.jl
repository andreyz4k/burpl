
using .Solutions: Solution, Block, FieldInfo, insert_operation, get_unmatched_complexity_score, persist_updates
using .Operations: Operation, Project
using .DataTransformers: match_fields
using .Abstractors: create
using .Taskdata: TaskData


struct FakeOperation <: Operation
    input_keys::Any
    output_keys::Any
    aux_keys::Any
end

(op::FakeOperation)(task_data) = task_data

make_taskdata(tasks) =
    TaskData(Dict{String,Vector}(), Dict(key => Any[task[key] for task in tasks] for key in keys(tasks[1])), Set())

make_taskdata(task::Dict) = TaskData(Dict{String,Vector}(), Dict(key => Any[val] for (key, val) in task), Set())

make_field_info(taskdata) = Dict(key => FieldInfo(vals[1], "input", [], [Set()]) for (key, vals) in taskdata)

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
        Set(["output"]),
        unused,
        Set(),
        Set(),
        0.0,
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
    Dict(
        key => values[i] for
        (key, values) in solution.taskdata if key != "input" && key != "output" && key != "projected|output"
    ) for (i, _) in enumerate(solution.taskdata["input"])
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

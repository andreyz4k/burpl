
using .Solutions:Solution,Block,FieldInfo,insert_operation
using .Operations:Operation,Project
using .DataTransformers:match_fields
using .Abstractors:create

make_sample_taskdata(len) =
    fill(Dict("input" => Array{Int}(undef, 0, 0), "output" => Array{Int}(undef, 0, 0)), len)

struct FakeOperation <: Operation
    input_keys
    output_keys
    aux_keys
end

(op::FakeOperation)(task_data) = task_data

make_field_info(taskdata) =
    Dict(key => FieldInfo(val, "input", [], [Set()]) for (key, val) in taskdata[1])

function make_dummy_solution(data, unfilled=[])
    unused = Set(filter(k -> !in(k, unfilled) && k != "input" && k != "output", keys(data[1])))
    taskdata = [merge(Dict("input" => Array{Int}(undef, 0, 0),
                         "output" => Array{Int}(undef, 0, 0)),
                    task)
              for task in data]
    Solution(taskdata,
             make_field_info(taskdata), [Block([FakeOperation(unfilled, ["output"], [])])], Set(unfilled), Set(), Set(), unused, Set(), Set(), 0.0)
end

function _compare_operations(expected, solutions)
    for solution in solutions
        ops = filtered_ops(solution)
        @test any(ops == bl for bl in expected)
        filter!(bl -> bl != ops, expected)
    end
    @test isempty(expected)
end

filtered_taskdata(solution) =
    [filter(keyval -> keyval[1] != "input" && keyval[1] != "output" && keyval[1] != "projected|output", task) for task in solution.taskdata]

filtered_ops(solution) =
    filter(op -> !isa(op, FakeOperation) && !isa(op, Project), vcat((block.operations for block in solution.blocks)...))

function create_solution(taskdata, operations)
    solution = Solution(taskdata)
    for (op_class, key, to_abs) in operations
        abstractor = create(op_class, solution, key)[1][2]
        if to_abs
            new_solution = insert_operation(solution, abstractor.to_abstract)
        else
            new_solution = insert_operation(solution, abstractor.from_abstract, reversed_op=abstractor.to_abstract)
        end
        solution = match_fields(new_solution)[1]
    end
    solution
end

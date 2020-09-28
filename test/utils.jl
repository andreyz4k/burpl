
using .Solutions:Solution, Block
using .Operations:Operation,Project

make_sample_taskdata(len) =
    fill(Dict("input" => Array{Int}(undef, 0, 0), "output" => Array{Int}(undef, 0, 0)), len)

struct FakeOperation <: Operation
    input_keys
    output_keys
end

(op::FakeOperation)(task_data) = task_data

make_dummy_solution(data, unfilled=[]) =
    Solution([merge(Dict("input" => Array{Int}(undef, 0, 0),
                         "output" => Array{Int}(undef, 0, 0)),
                    task)
              for task in data],
             [Block([FakeOperation(unfilled, ["output"])])], Set(unfilled), Set(), Set(), Set(), Set(), Set(), 0.0)

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

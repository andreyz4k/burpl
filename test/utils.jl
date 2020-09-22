
using .SolutionOps:Solution, Block

make_sample_taskdata(len) =
    fill(Dict("input" => Array{Int}(undef, 0, 0), "output" => Array{Int}(undef, 0, 0)), len)

make_dummy_solution(data, unfilled=[]) =
    Solution([merge(Dict("input" => Array{Int}(undef, 0, 0),
                         "output" => Array{Int}(undef, 0, 0)),
                    task)
              for task in data],
             [Block()], Set(unfilled), Set(), Set(), Set(), Set(), 0.0)

function _compare_operations(expected, solutions)
    for solution in solutions
        @test any(solution.blocks[end].operations == bl for bl in expected)
        filter!(bl -> bl != solution.blocks[end].operations, expected)
    end
    @test isempty(expected)
end

filtered_taskdata(solution) =
    [filter(keyval -> keyval[1] != "input" && keyval[1] != "output" && keyval[1] != "projected|output", task) for task in solution.taskdata]

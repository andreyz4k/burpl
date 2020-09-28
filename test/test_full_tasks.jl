
TASKS = [
    "../data/training/ff28f65a.json",
    "../data/training/0a938d79.json",
    # "../data/training/0b148d64.json",
]

using Randy:get_solution,test_solution

@testset "Full tasks" for fname in TASKS
    @testset "run task" begin
        solution = get_solution(fname)
        @test test_solution(solution, fname) == (0, 0)
    end
end

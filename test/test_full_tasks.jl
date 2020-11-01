
TASKS = [
    "../data/training/ff28f65a.json",
    "../data/training/0a938d79.json",
    "../data/training/0b148d64.json",
]

using Randy:get_solution,test_solution

@testset "Full tasks" begin
    @testset "run task $fname" for fname in TASKS
        solution = get_solution(fname)
        @test test_solution(solution, fname) == (0, 0)
    end
end

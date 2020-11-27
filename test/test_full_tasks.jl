
TASKS = [
    "../data/training/0a938d79.json",
    "../data/training/0b148d64.json",
    "../data/training/1cf80156.json",
    "../data/training/25ff71a9.json",
    "../data/training/39a8645d.json",
    "../data/training/5521c0d9.json",
    "../data/training/5582e5ca.json",
    "../data/training/74dd1130.json",
    "../data/training/9dfd6313.json",
    "../data/training/b1948b0a.json",
    "../data/training/d0f5fe59.json",
    "../data/training/d13f3404.json",
    "../data/training/ff28f65a.json",
]

using Randy:get_solution,test_solution

@testset "Full tasks" begin
    @testset "run task $fname" for fname in TASKS
        solution = get_solution(fname)
        @test test_solution(solution, fname) == (0, 0)
    end
end


TASKS = [
    "../data/training/0a938d79.json",
    "../data/training/0b148d64.json",
    "../data/training/1cf80156.json",
    "../data/training/25ff71a9.json",
    "../data/training/39a8645d.json",
    "../data/training/496994bd.json",
    "../data/training/4c4377d9.json",
    "../data/training/5582e5ca.json",
    "../data/training/62c24649.json",
    "../data/training/6d0aefbc.json",
    "../data/training/6fa7a44f.json",
    "../data/training/74dd1130.json",
    "../data/training/8be77c9e.json",
    "../data/training/9dfd6313.json",
    "../data/training/b1948b0a.json",
    "../data/training/c9e6f938.json",
    "../data/training/d0f5fe59.json",
    "../data/training/d13f3404.json",
    "../data/training/ea786f4a.json",
    "../data/training/eb281b96.json",
    "../data/training/f25ffba3.json",
    "../data/training/ff28f65a.json",
]

UNSOLVED_TASKS = [
    "../data/training/5521c0d9.json",
]

FAILING_TASKS = [
    # "../data/training/2dd70a9a.json",
    # "../data/training/7df24a62.json",

    "../data/training/22eb0ac0.json",
]

using burpl: solve_and_check

@testset "Full tasks" begin
    @testset "run task $fname" for fname in TASKS
        @time begin
            @test solve_and_check(fname)
        end
    end

    @testset "run task $fname" for fname in UNSOLVED_TASKS
        @time begin
            @test !solve_and_check(fname)
        end
    end
end


TASKS = [
    "../data/training/0a938d79.json",
    "../data/training/0b148d64.json",
    "../data/training/1cf80156.json",
    "../data/training/25ff71a9.json",
    "../data/training/39a8645d.json",
    "../data/training/3af2c5a8.json",
    "../data/training/3c9b0459.json",
    "../data/training/496994bd.json",
    "../data/training/4c4377d9.json",
    "../data/training/5582e5ca.json",
    "../data/training/62c24649.json",
    "../data/training/6d0aefbc.json",
    "../data/training/68b16354.json",
    "../data/training/6fa7a44f.json",
    "../data/training/74dd1130.json",
    "../data/training/8be77c9e.json",
    "../data/training/9172f3a0.json",
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
    "../data/training/23b5c85d.json",
    "../data/training/5521c0d9.json",
]

FAILING_TASKS = [
    # "../data/training/2dd70a9a.json",
    # "../data/training/7df24a62.json",

    "../data/training/22eb0ac0.json",
]

using burpl: solve_and_check
using Base.Iterators: flatten
using Base.Threads: @spawn
using GitHubActions: set_env
using Test: Pass

@testset "Full tasks" begin
    futures = Dict()
    @info("Numthreads: $(Threads.nthreads())")
    asyncmap(flatten([TASKS, UNSOLVED_TASKS]), ntasks = Threads.nthreads()) do fname
        @time begin
            fut = @spawn solve_and_check(fname)
            futures[fname] = fut
            timedwait(() -> istaskdone(fut), 300)
            if !istaskdone(fut)
                try
                    schedule(fut, ErrorException("Timeout error"), error = true)
                catch ex
                    @warn(ex)
                end
            end
        end
    end

    success_count = 0

    @testset "run task $fname" for fname in TASKS
        fut = futures[fname]
        test_result = @test !istaskfailed(fut) && fetch(fut)
        if isa(test_result, Pass)
            success_count += 1
        end
    end

    @testset "run task $fname" for fname in UNSOLVED_TASKS
        fut = futures[fname]
        @test !istaskfailed(fut) && !fetch(fut)
    end
    @info("Success count $success_count")
    get(ENV, "GITHUB_ACTIONS", "false") == "true" && set_env("TRAIN_SOLVES", success_count)
end


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
    "../data/training/6150a2bd.json",
    "../data/training/62c24649.json",
    "../data/training/67a3c6ac.json",
    "../data/training/67e8384a.json",
    "../data/training/68b16354.json",
    "../data/training/6d0aefbc.json",
    "../data/training/6fa7a44f.json",
    "../data/training/7468f01a.json",
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

function run_tasks(ch, tasks)
    asyncmap(tasks, ntasks = Threads.nthreads()) do fname
        @time begin
            fut = @spawn solve_and_check(fname)
            timedwait(() -> istaskdone(fut), 300)
            if !istaskdone(fut)
                try
                    schedule(fut, ErrorException("Timeout error"), error = true)
                catch ex
                    @warn(ex)
                end
            end
            put!(ch, (fname, fut))
        end
    end
end

@testset "Full tasks" begin
    @info("Numthreads: $(Threads.nthreads())")
    taskref = Ref{Task}()
    chnl = Channel(taskref=taskref) do ch
        run_tasks(ch, TASKS)
    end

    success_count = 0

    try
        for _ in 1:length(TASKS)
            (fname, fut) = take!(chnl)
            @testset "run task $fname" begin
                test_result = @test istaskdone(fut) && !istaskfailed(fut) && fetch(fut)
                if isa(test_result, Pass)
                    success_count += 1
                end
            end
        end
    catch ex
        schedule(taskref, ex, error=true)
        rethrow()
    end


    chnl = Channel(taskref=taskref) do ch
        run_tasks(ch, UNSOLVED_TASKS)
    end

    try
        for _ in 1:length(UNSOLVED_TASKS)
            (fname, fut) = take!(chnl)
            @testset "run task $fname" begin
                @test istaskdone(fut) && !istaskfailed(fut) && !fetch(fut)
            end
        end
    catch ex
        schedule(taskref, ex, error=true)
        rethrow()
    end

    @info("Success count $success_count")
    get(ENV, "GITHUB_ACTIONS", "false") == "true" && set_env("TRAIN_SOLVES", success_count)
end

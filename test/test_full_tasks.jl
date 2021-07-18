using Base: with_logger, SimpleLogger

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
using Test: Pass, AbstractTestSet, Error, Fail, Broken, DefaultTestSet

import Test: record, finish

mutable struct LogFilterTestSet{T<:AbstractTestSet} <: AbstractTestSet
    wrapped::T
    description::String
    log_file::String
    stdout_file::String
    LogFilterTestSet{T}(desc, log_file, stdout_file) where {T} = new(T(desc), desc, log_file, stdout_file)
end
LogFilterTestSet(desc; log_file = nothing, stdout_file = nothing, wrap = DefaultTestSet) =
    LogFilterTestSet{wrap}(desc, log_file, stdout_file)


record(ts::LogFilterTestSet, t) = record(ts.wrapped, t)

function record(ts::LogFilterTestSet, t::Union{Fail,Error})
    println("\n=====================================================")
    printstyled(ts.description, "\n"; color = :white)
    printstyled("Captured log output:\n"; color = :white)
    for line in eachline(ts.log_file)
        println(line)
    end
    printstyled("Captured stdout output:\n"; color = :white)
    for line in eachline(ts.stdout_file)
        println(line)
    end
    record(ts.wrapped, t)
end


function finish(ts::LogFilterTestSet)
    finish(ts.wrapped)
end

function run_tasks(ch, tasks)
    asyncmap(tasks, ntasks = Threads.nthreads()) do fname
        (log_file, log_io) = mktemp()
        (stdout_file, stdout_io) = mktemp()
        redirect_stdout(stdout_io) do
            with_logger(SimpleLogger(log_io)) do
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
                end
                flush(stdout_io)
                flush(log_io)
                put!(ch, (fname, fut, log_file, stdout_file))
            end
        end

    end
end

@testset "Full tasks" begin
    @info("Numthreads: $(Threads.nthreads())")
    taskref = Ref{Task}()
    chnl = Channel(10, taskref = taskref) do ch
        run_tasks(ch, flatten([TASKS, UNSOLVED_TASKS]))
    end

    success_count = 0

    try
        for _ = 1:length(TASKS)+length(UNSOLVED_TASKS)
            (fname, fut, log_file, stdout_file) = take!(chnl)
            @info(fname, log_file, stdout_file)
            @testset LogFilterTestSet "run task $fname" log_file = log_file stdout_file = stdout_file wrap =
                ExtendedTestSet begin
                if in(fname, TASKS)
                    test_result = @test fetch(fut)
                    if isa(test_result, Pass)
                        success_count += 1
                    end
                else
                    @test !fetch(fut)
                end
            end
        end
    catch ex
        if !istaskdone(taskref[])
            schedule(taskref[], ex, error = true)
        end
        rethrow()
    end

    @info("Success count $success_count")
    get(ENV, "GITHUB_ACTIONS", "false") == "true" && set_env("TRAIN_SOLVES", success_count)
end

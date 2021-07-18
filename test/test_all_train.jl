

using burpl: solve_and_check
using Base.Threads: @spawn

skip = [
    "../data/training/2dd70a9a.json",
    "../data/training/7df24a62.json",
    "../data/training/46f33fce.json",
    "../data/training/9edfc990.json",
    "../data/training/ac0a08a4.json",
    "../data/training/e26a3af2.json",
]

function run_tasks(ch, tasks)
    asyncmap(tasks, ntasks = Threads.nthreads()) do fname
        (log_file, log_io) = mktemp()
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
                flush(log_io)
                put!(ch, (fname, fut, log_file))
            end
        end
    end
end

@testset "Run all train tasks" begin
    return
    files = readdir("../data/training", join = true)[1:100]

    @info("Numthreads: $(Threads.nthreads())")
    taskref = Ref{Task}()
    chnl = Channel(10, taskref = taskref) do ch
        run_tasks(ch, files)
    end

    try
        for _ = 1:length(files)
            if istaskdone(taskref[]) && !isready(chnl)
                break
            end
            (fname, fut, log_file) = take!(chnl)
            @testset LogFilterTestSet "run task $fname" log_file = log_file wrap = ExtendedTestSet begin
                @test fetch(fut)
            end
        end
    catch ex
        if !istaskdone(taskref[])
            schedule(taskref[], ex, error = true)
        end
        rethrow()
    end
end

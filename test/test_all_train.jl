

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

@testset "Run all train tasks" begin
    return
    files = readdir("../data/training", join = true)

    futures = Dict()
    @info("Numthreads: $(Threads.nthreads())")
    asyncmap(files, ntasks = Threads.nthreads()) do fname
        @time begin
            fut = @spawn solve_and_check(fname)
            futures[fname] = fut
            timedwait(() -> istaskdone(fut), 300)
            if !istaskdone(fut)
                schedule(fut, ErrorException("Timeout error"), error = true)
        end
        end
    end

    @testset "run task $fname" for fname in files
        fut = futures[fname]
        @test istaskdone(fut) && fetch(fut)
    end
end

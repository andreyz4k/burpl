

using .burpl:solve_and_check

skip  = [
    "../data/training/2dd70a9a.json",
    "../data/training/7df24a62.json",
    "../data/training/46f33fce.json",
    "../data/training/9edfc990.json",
    "../data/training/ac0a08a4.json",
    "../data/training/e26a3af2.json",
]

@testset "Run all train tasks" begin
    return
    files = readdir("../data/training", join=true)
    @testset "test file $fname" for fname in files[301:400]
        if in(fname, skip)
            continue
        end
        @time begin
            @test solve_and_check(fname)
        end
    end
end

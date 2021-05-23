

using burpl:get_solution,test_solution

skip  = [
    # "../data/training/264363fd.json",
    # "../data/training/29ec7d0e.json",
    # "../data/training/484b58aa.json",
    # "../data/training/49d1d64f.json",
    # "../data/training/4be741c5.json",
    # "../data/training/539a4f51.json",
    # "../data/training/54d9e175.json",
    # "../data/training/5bd6f4ac.json",
    # "../data/training/662c240a.json",
    # "../data/training/67a3c6ac.json",
    # "../data/training/68b16354.json",
]

@testset "Run all train tasks" begin
    return
    files = readdir("../data/training", join=true)
    @testset "test file $fname" for fname in files[301:400]
        if in(fname, skip)
            continue
        end
        solution = get_solution(fname)
        @test test_solution(solution, fname) == (0, 0)
    end
end

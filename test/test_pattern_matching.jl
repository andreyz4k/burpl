make_sample_taskdata(len) =
    fill(Dict("input" => Array{Int}(undef, 0, 0), "output" => Array{Int}(undef, 0, 0)), len)

make_dummy_solution(data, unfilled=[]) =
    Solution(make_sample_taskdata(length(data)), [Block()],
    [Array{Int}(undef, 0, 0) for _ in 1:length(data)], data, Set(unfilled), Set(), Set(), Set(), Set(), 0.0)

using .SolutionOps:Solution, find_const, match_fields, Block
using .DataTransformers:SetConst

@testset "Patten Matching" begin
    @testset "Find const" begin
        solution = make_dummy_solution([
                Dict(
                    "background" => 1
                ),
                Dict(
                    "background" => 1
                )
            ]
        )
        @test find_const(solution, "background") == [1]

        solution = make_dummy_solution([
                Dict(
                    "background" => 1
                ),
                Dict(
                    "background" => Either.create_simple(Set([1, 2]))
                )
            ]
        )
        @test find_const(solution, "background") == [1]

        solution = make_dummy_solution([
                Dict(
                    "background" => Either.create_simple(Set([1, 2]))
                ),
                Dict(
                    "background" => 1
                ),
            ]
        )
        @test find_const(solution, "background") == [1]

        solution = make_dummy_solution([
                Dict(
                    "background" => Either.create_simple(Set([1, 2]))
                ),
                Dict(
                    "background" => Either.create_simple(Set([1, 3]))
                ),
            ]
        )
        @test find_const(solution, "background") == [1]

        solution = make_dummy_solution([
                Dict(
                    "background" => Either.create_simple(Set([1, 2]))
                ),
                Dict(
                    "background" => Either.create_simple(Set([1, 2]))
                ),
            ]
        )
        @test Set(find_const(solution, "background")) == Set([1, 2])

    end

    @testset "Match data" begin
        solution = make_dummy_solution([
               Dict(
                    "background" => 1
                ),
                Dict(
                    "background" => 1
                )
            ],
            ["background"]
        )
        new_solutions = match_fields(solution)
        @test length(new_solutions) == 1
        new_solution = new_solutions[1]
        @test new_solution.blocks[end].operations == [SetConst("background", 1)]
    end

end

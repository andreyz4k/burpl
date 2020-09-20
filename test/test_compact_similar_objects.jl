
using .Operations:CompactSimilarObjects,create
using .ObjectPrior:Object

@testset "Compact similar objects" begin
    @testset "reshape objects" begin
        source_data = Dict{String,Any}(
            "key" => [
                Object([1], (1, 1)),
                Object([1], (2, 3)),
            ]
        )
        reshaper = CompactSimilarObjects("key", true)
        out_data = reshaper(source_data)
        @test out_data == Dict(
            "key" => [
                Object([1], (1, 1)),
                Object([1], (2, 3)),
            ],
            "key|common_shape" => fill(1, 1, 1),
            "key|positions" => [
                (1, 1),
                (2, 3)
            ]
        )
        delete!(out_data, "key")
        reshaper = CompactSimilarObjects("key", false)
        reversed_data = reshaper(out_data)
        @test reversed_data["key"] == source_data["key"]
    end

    @testset "get reshaper" begin
        solution = make_dummy_solution([
            Dict(
                "key" => [
                    Object([1], (1, 1)),
                    Object([1], (2, 3)),
                ]
            ),
            Dict(
                "key" => [
                    Object([1], (1, 1)),
                ]
            ),
            Dict(
                "key" => [
                    Object([1], (1, 1)),
                    Object([1], (2, 3)),
                    Object([1], (3, 3)),
                ]
            )
        ])
        abstractors = create(CompactSimilarObjects(), solution, "key")
        @test length(abstractors) == 1
        priority, abstractor = abstractors[1]
        @test priority == 8
        @test abstractor.to_abstract == CompactSimilarObjects("key", true)
        @test abstractor.to_abstract.output_keys == ["key|common_shape", "key|positions"]
        @test abstractor.from_abstract == CompactSimilarObjects("key", false)
        @test abstractor.from_abstract.input_keys == ["key|common_shape", "key|positions"]
    end
end

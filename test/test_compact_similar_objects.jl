
using .Abstractors: CompactSimilarObjects, create
using .ObjectPrior: Object
using .PatternMatching: ObjectShape, common_value

@testset "Compact similar objects" begin
    @testset "reshape objects" begin
        source_data = make_taskdata(Dict{String,Any}("key" => Set([Object([1], (1, 1)), Object([1], (2, 3))])))
        reshaper = CompactSimilarObjects("key", true)
        out_data = reshaper(source_data)
        @test out_data == Dict(
            "key" => [Set([Object([1], (1, 1)), Object([1], (2, 3))])],
            "key|common_shape" => [ObjectShape(Object([1], (1, 1)))],
            "key|positions" => [Set([(1, 1), (2, 3)])],
        )
        delete!(out_data, "key")
        reshaper = CompactSimilarObjects("key", false)
        reversed_data = reshaper(out_data)
        @test !isnothing(common_value(reversed_data["key"], source_data["key"]))
    end

    @testset "get reshaper" begin
        solution = make_dummy_solution([
            Dict("key" => Set([Object([1], (1, 1)), Object([1], (2, 3))])),
            Dict("key" => Set([Object([1], (1, 1))])),
            Dict("key" => Set([Object([1], (1, 1)), Object([1], (2, 3)), Object([1], (3, 3))])),
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

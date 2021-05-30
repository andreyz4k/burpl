import .Abstractors:GroupObjectsByColor,create
import .ObjectPrior:Object,Color

@testset "Group objects by color" begin
    @testset "group objects" begin
        source_data = make_taskdata(Dict{String,Any}(
            "key" => Set([
                Object([1], (1, 1)),
                Object([1 1], (2, 4)),
                Object([2], (2, 2)),
                Object([3], (9, 1)),
                Object([2], (1, 3)),
            ])
        ))
        grouper = GroupObjectsByColor("key", true)
        out_data = grouper(source_data)
        @test out_data == Dict(
            "key" => Set([
                Object([1], (1, 1)),
                Object([1 1], (2, 4)),
                Object([2], (2, 2)),
                Object([3], (9, 1)),
                Object([2], (1, 3)),
            ]),
            "key|grouped" => Dict(
                Color(1) => Set([
                    Object([1], (1, 1)),
                    Object([1 1], (2, 4)),
                ]),
                Color(2) => Set([
                    Object([2], (2, 2)),
                    Object([2], (1, 3)),
                ]),
                Color(3) => Set([
                    Object([3], (9, 1)),
                ])
            ),
            "key|group_keys" => Set([Color(1), Color(2), Color(3)])
        )
        delete!(out_data, "key")
        ungrouper = GroupObjectsByColor("key", false)
        @test issetequal(ungrouper(out_data)["key"], source_data["key"])
    end

    @testset "get grouper" begin
        solution = make_dummy_solution([
                Dict(
                    "key" => Set([
                        Object([1], (1, 1)),
                        Object([1 1], (2, 4)),
                        Object([2], (2, 2)),
                        Object([3], (9, 1)),
                        Object([2], (1, 3)),
                    ])
                ),
                Dict(
                    "key" => Set([
                        Object([1], (1, 1)),
                        Object([1], (2, 3)),
                        Object([3], (9, 1)),
                        Object([2 2], (3, 5)),
                    ])
                ),
                Dict(
                    "key" => Set([
                        Object([1], (1, 1)),
                        Object([1], (2, 3)),
                        Object([3], (9, 1)),
                        Object([2 2], (3, 5)),
                        Object([2], (1, 3)),
                        Object([4], (4, 4)),
                    ])
                ),
            ], ["key"])
        groupers = create(GroupObjectsByColor(), solution, "key")
        @test length(groupers) == 1
        priority, grouper = groupers[1]
        @test priority == 8
        @test grouper.to_abstract.input_keys == ["key"]
        @test grouper.to_abstract.output_keys == ["key|grouped", "key|group_keys"]
        @test grouper.from_abstract.input_keys == ["key|grouped", "key|group_keys"]
        @test grouper.from_abstract.output_keys == ["key"]
    end

    @testset "get no grouper" begin
        solution = make_dummy_solution([
                Dict(
                    "key" => Set([
                        ([1], (1, 1)),
                        ([1 1], (2, 4)),
                        ([2], (2, 2)),
                        ([3], (9, 1)),
                        ([2], (1, 3)),
                    ])
                ),
                Dict(
                    "key" => Set([
                        ([1], (1, 1)),
                        ([1], (2, 3)),
                        ([3], (9, 1)),
                        ([2 2], (3, 5)),
                    ])
                ),
                Dict(
                    "key" => Set([
                        ([1], (1, 1)),
                        ([1], (2, 3)),
                        ([3], (9, 1)),
                        ([2 2], (3, 5)),
                        ([2], (1, 3)),
                        ([4], (4, 4)),
                    ])
                ),
            ], ["key"])
        @test create(GroupObjectsByColor(), solution, "key") == []
    end
end

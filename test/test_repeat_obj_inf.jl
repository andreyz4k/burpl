
using .ObjectPrior:Object
using .Abstractors:check_task_value,RepeatObjectInfinite,create
using .PatternMatching:Either,Option

@testset "Repeat object infinite" begin
    @testset "simple repeat" begin
        value = Set([
            Object([1], (1, 1)),
            Object([1], (2, 1)),
            Object([1], (3, 1)),
        ])
        data = Dict("effective" => false)
        @test check_task_value(RepeatObjectInfinite(), value, data, [(3, 3)]) == true
        @test data["effective"] == true
    end

    @testset "different objects" begin
        value = Set([
            Object([1], (1, 1)),
            Object([1 1], (2, 1)),
            Object([1], (3, 1)),
        ])
        data = Dict("effective" => false)
        @test check_task_value(RepeatObjectInfinite(), value, data, [(3, 3)]) == false
    end

    @testset "not infinite" begin
        value = Set([
            Object([1], (1, 1)),
            Object([1], (2, 1)),
            Object([1], (3, 1)),
        ])
        data = Dict("effective" => false)
        @test check_task_value(RepeatObjectInfinite(), value, data, [(4, 4)]) == true
        @test data["effective"] == true
        value = Set([
            Object([1], (1, 1)),
            Object([1], (2, 1)),
            Object([1], (3, 1)),
            Object([1], (4, 1)),
        ])
        data = Dict("effective" => false)
        @test check_task_value(RepeatObjectInfinite(), value, data, [(4, 4)]) == true
        @test data["effective"] == true
        value = Set([
            Object([1], (2, 1)),
            Object([1], (3, 1)),
        ])
        data = Dict("effective" => false)
        @test check_task_value(RepeatObjectInfinite(), value, data, [(4, 4)]) == false
        @test data["effective"] == true
    end

    @testset "repeat object" begin
        source_data = make_taskdata(Dict(
            "input|key" => Set([
                Object([1], (1, 1)),
                Object([1], (2, 2)),
                Object([1], (3, 3)),
            ]),
            "input|grid_size" => (3, 3)
        ))
        repeater = RepeatObjectInfinite("input|key", true, source_data)
        out_data = repeater(source_data)
        @test out_data == Dict(
            "input|key" => Set([
                Object([1], (1, 1)),
                Object([1], (2, 2)),
                Object([1], (3, 3)),
            ]),
            "input|key|first" => Either([
                Option(
                    Object([1], (1, 1)),
                    hash((Object([1], (1, 1)), (1, 1)))
                ),
                Option(
                    Object([1], (3, 3)),
                    hash((Object([1], (3, 3)), (-1, -1)))
                )
            ]),
            "input|key|step" => Either([
                Option(
                    (1, 1),
                    hash((Object([1], (1, 1)), (1, 1)))
                ),
                Option(
                    (-1, -1),
                    hash((Object([1], (3, 3)), (-1, -1)))
                )
            ]),
            "input|grid_size" => (3, 3)
        )
        delete!(out_data, "input|key")
        abs_data = make_taskdata(Dict(
            "input|key|first" => Object([1], (1, 1)),
            "input|key|step" => (1, 1),
            "input|grid_size" => (3, 3)
        ))
        repeater = RepeatObjectInfinite("input|key", false, source_data)
        reversed_data = repeater(abs_data)
        @test reversed_data["input|key"] == source_data["input|key"]
        abs_data = make_taskdata(Dict(
            "input|key|first" => Object([1], (3, 3)),
            "input|key|step" => (-1, -1),
            "input|grid_size" => (3, 3)
        ))
        reversed_data = repeater(abs_data)
        @test Set(reversed_data["input|key"]) == Set(source_data["input|key"])
    end

    @testset "get object repeater" begin
        solution = make_dummy_solution([
            Dict(
                "input|key" => Set([
                    Object([1], (1, 1)),
                    Object([1], (2, 3)),
                ]),
                "input|grid_size" => (3, 3)
            ),
            Dict(
                "input|key" => Set([
                    Object([1], (1, 1)),
                ]),
                "input|grid_size" => (3, 3)
            ),
            Dict(
                "input|key" => Set([
                    Object([1], (1, 1)),
                    Object([1], (2, 2)),
                    Object([1], (3, 3)),
                ]),
                "input|grid_size" => (3, 3)
            )
        ])
        abstractors = create(RepeatObjectInfinite(), solution, "input|key")
        @test length(abstractors) == 1
        for (priority, reshaper) in abstractors
    @test priority == 8.8
    @test reshaper.to_abstract.input_keys == ["input|key", "input|grid_size"]
    @test reshaper.to_abstract.output_keys == ["input|key|first", "input|key|step"]
    @test reshaper.from_abstract.input_keys == ["input|key|first", "input|key|step", "input|grid_size"]
    @test reshaper.from_abstract.output_keys == ["input|key"]
end

        solution = make_dummy_solution([
            Dict(
                "input|key" => Set([
                    Object([1], (1, 1)),
                    Object([1], (2, 3)),
                ]),
                "input|grid_size" => (3, 3)
            ),
            Dict(
                "input|key" => Set([
                    Object([1], (1, 1)),
                ]),
                "input|grid_size" => (3, 3)
            ),
            Dict(
                "input|key" => Set([
                    Object([1], (1, 1)),
                    Object([1], (2, 3)),
                    Object([1], (3, 3)),
                ]),
                "input|grid_size" => (3, 3)
            )
        ])
        @test create(RepeatObjectInfinite(), solution, "input|key") == []
    end

    @testset "get repeater" begin
        solution = make_dummy_solution([
            Dict(
                "input|spatial_objects|grid_size" => (10, 25),
                "input|spatial_objects|grouped|0" => Dict(
                    2 => Set([
                        Object([2 2 2 2 2 2 2 2 2 2], (1, 10)),
                        Object([2 2 2 2 2 2 2 2 2 2], (1, 22)),
                        Object([2 2 2 2 2 2 2 2 2 2], (1, 18)),
                        Object([2 2 2 2 2 2 2 2 2 2], (1, 6)),
                        Object([2 2 2 2 2 2 2 2 2 2], (1, 14)),
                    ]),
                    8 => Set([
                        Object([8 8 8 8 8 8 8 8 8 8], (1, 20)),
                        Object([8 8 8 8 8 8 8 8 8 8], (1, 16)),
                        Object([8 8 8 8 8 8 8 8 8 8], (1, 24)),
                        Object([8 8 8 8 8 8 8 8 8 8], (1, 12)),
                        Object([8 8 8 8 8 8 8 8 8 8], (1, 8)),
                    ])
                )
            ),
            Dict(
                "input|spatial_objects|grid_size" => (7, 23),
                "input|spatial_objects|grouped|0" => Dict(
                    1 => Set([
                        Object([1 1 1 1 1 1 1], (1, 18)),
                        Object([1 1 1 1 1 1 1], (1, 6)),
                        Object([1 1 1 1 1 1 1], (1, 12)),
                    ]),
                    3 => Set([
                        Object([3 3 3 3 3 3 3], (1, 15)),
                        Object([3 3 3 3 3 3 3], (1, 9)),
                        Object([3 3 3 3 3 3 3], (1, 21)),
                    ])
                )
            )
        ])
        abstractors = create(RepeatObjectInfinite(), solution, "input|spatial_objects|grouped|0")
        @test length(abstractors) == 1
    end
end

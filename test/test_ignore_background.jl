
using .ObjectPrior:Object
using .Abstractors:IgnoreBackground

@testset "Ignore background" begin
    @testset "get ignore background" begin
        solution = make_dummy_solution([
                Dict(
                    "output|spatial_objects|selected_by|0|background" => [
                        Object([-1 0 0; 0 0 0; 0 0 0], (1, 1))
                    ],
                    "output|spatial_objects|rejected_by|0|background" => [
                        Object([1], (1, 1))
                    ],
                    "output|background" => 0
                ),
                Dict(
                    "output|spatial_objects|selected_by|0|background" => [
                        Object([-1 0 -1; 0 0 0; 0 0 0], (1, 1))
                    ],
                    "output|spatial_objects|rejected_by|0|background" => [
                        Object([1], (1, 1)),
                        Object([1], (1, 3))
                    ],
                    "output|background" => 0
                ),
                Dict(
                    "output|spatial_objects|selected_by|0|background" => [
                        Object([0 -1 0; 0 0 0], (2, 1)),
                        Object([0], (1, 2))
                    ],
                    "output|spatial_objects|rejected_by|0|background" => [
                        Object([1], (1, 1)),
                        Object([1], (1, 3)),
                        Object([1], (2, 2))
                    ],
                    "output|background" => 0
                ),
                Dict(
                    "output|spatial_objects|selected_by|0|background" => [
                        Object([-1 0 -1; 0 0 0; 0 0 0], (1, 1))
                    ],
                    "output|spatial_objects|rejected_by|0|background" => [
                        Object([1], (1, 1)),
                        Object([1], (1, 3))
                    ],
                    "output|background" => 0
                ),
                Dict(
                    "output|spatial_objects|selected_by|0|background" => [
                        Object([-1 0 0; 0 0 0; 0 0 0], (1, 1))
                    ],
                    "output|spatial_objects|rejected_by|0|background" => [
                        Object([1], (1, 1))
                    ],
                    "output|background" => 0
                ),
                Dict(
                    "output|spatial_objects|selected_by|0|background" => [
                        Object([0], (2, 1)),
                        Object([-1 0; 0 0], (2, 2)),
                        Object([0], (1, 2))
                    ],
                    "output|spatial_objects|rejected_by|0|background" => [
                        Object([1], (1, 1)),
                        Object([1], (3, 1)),
                        Object([1], (1, 3)),
                        Object([1], (2, 2)),
                    ],
                    "output|background" => 0
                ),
                Dict(
                    "output|spatial_objects|selected_by|0|background" => [
                        Object([0], (2, 1)),
                        Object([0], (2, 3)),
                        Object([0], (1, 2)),
                        Object([0], (3, 2)),
                    ],
                    "output|spatial_objects|rejected_by|0|background" => [
                        Object([1], (1, 1)),
                        Object([1], (3, 1)),
                        Object([1], (1, 3)),
                        Object([1], (2, 2)),
                        Object([1], (3, 3)),
                    ],
                    "output|background" => 0
                ),
                Dict(
                    "output|spatial_objects|selected_by|0|background" => [
                        Object([0], (2, 1)),
                        Object([-1 0; 0 0], (2, 2)),
                        Object([0], (1, 2))
                    ],
                    "output|spatial_objects|rejected_by|0|background" => [
                        Object([1], (1, 1)),
                        Object([1], (3, 1)),
                        Object([1], (1, 3)),
                        Object([1], (2, 2)),
                    ],
                    "output|background" => 0
                )
            ],
            ["output|spatial_objects|selected_by|0|background", "output|spatial_objects|rejected_by|0|background"]
        )
        abstractors = create(IgnoreBackground(), solution, "output|spatial_objects|selected_by|0|background")
        @test length(abstractors) == 1
        priority, abstractor = abstractors[1]
        @test abstractor.to_abstract == IgnoreBackground("output|spatial_objects|selected_by|0|background", true)
        @test abstractor.from_abstract == IgnoreBackground("output|spatial_objects|selected_by|0|background", false)
    end
end

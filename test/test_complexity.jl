using .Solutions:get_unmatched_complexity_score
using .Complexity:get_complexity,get_generability
using .ObjectPrior:Object
using .DataTransformers:MapValues

@testset "Complexity" begin
    @testset "ideal solution" begin
        @test get_unmatched_complexity_score(
                make_dummy_solution([Dict(
                    "input" => zeros(Int, 1, 1),
                    "output" => zeros(Int, 1, 1)
                )], [])
            ) == 0
    end

    @testset "simple value" begin
        @test get_complexity(5) == 1
        @test get_complexity(123) == 1
    end

    @testset "tuple" begin
        @test get_complexity((1,)) == 4
        @test get_complexity((1, 2)) == 4.95
        @test get_complexity((1, 2, 234)) == 5.85375
    end

    @testset "list" begin
        @test get_complexity([1, 2]) == 6.95
        @test get_complexity([34, 234, 32]) == 7.85375
    end

    @testset "shape" begin
        @test get_complexity(fill(0, 1, 1)) == 9
        @test get_complexity(fill(0, 1, 2)) == 12.8
        @test get_complexity([
            0 0 0 0 0 0 0 0 0 0;
            0 0 0 0 0 0 0 0 0 0;
            0 0 0 0 0 0 0 0 0 0;
            0 0 0 0 0 0 0 0 0 0;
            0 0 0 0 0 0 0 0 0 0;
            2 2 2 2 2 2 2 2 2 2;
            0 0 0 0 0 0 0 0 0 0;
            8 8 8 8 8 8 8 8 8 8;
            0 0 0 0 0 0 0 0 0 0;
            2 2 2 2 2 2 2 2 2 2;
            0 0 0 0 0 0 0 0 0 0;
            8 8 8 8 8 8 8 8 8 8;
            0 0 0 0 0 0 0 0 0 0;
            2 2 2 2 2 2 2 2 2 2;
            0 0 0 0 0 0 0 0 0 0;
            8 8 8 8 8 8 8 8 8 8;
            0 0 0 0 0 0 0 0 0 0;
            2 2 2 2 2 2 2 2 2 2;
            0 0 0 0 0 0 0 0 0 0;
            8 8 8 8 8 8 8 8 8 8;
            0 0 0 0 0 0 0 0 0 0;
            2 2 2 2 2 2 2 2 2 2;
            0 0 0 0 0 0 0 0 0 0;
            8 8 8 8 8 8 8 8 8 8;
            0 0 0 0 0 0 0 0 0 0
        ]) == 505.0014195402831
    end

    @testset "object" begin
        @test get_complexity(Object([0], (1, 1))) == 13.95
        @test get_complexity(Object([0 1], (1, 1))) == 17.75
    end

    @testset "reshape" begin
        val1 = [
            Object([0], (1, 1)),
            Object([0], (2, 1))
        ]
        val2 = fill(0, 1, 1)
        val3 = [
            (1, 1),
            (2, 1)
        ]
        @test get_complexity(val1) == 32.2025
        @test get_complexity(val2) == 9
        @test get_complexity(val3) == 14.6525
        @test get_complexity(val1) > get_complexity(val2) + get_complexity(val3)

        val1 = [
            Object([0], (1, 1))
        ]
        val2 = fill(0, 1, 1)
        val3 = [(1, 1)]
        @test get_complexity(val1) == 18.95
        @test get_complexity(val2) == 9
        @test get_complexity(val3) == 9.95
        @test get_complexity(val1) == get_complexity(val2) + get_complexity(val3)
    end

    @testset "dict" begin
        data = Dict(
            "a" => 12,
            "b" => 10
        )
        @test get_complexity(data) == 5
        data = Dict(
            "a" => Object([0], (1, 1)),
            "b" => Object([0], (2, 1)),
        )
        @test get_complexity(data) == 30.9
    end

    @testset "group" begin
        val1 = [
            Object([0], (1, 1)),
            Object([0], (2, 1))
        ]
        val2 = Dict(
            0 => [
                Object([0], (1, 1)),
                Object([0], (2, 1))
            ]
        )
        @test get_complexity(val1) < get_complexity(val2)
        val1 = [
            Object([0], (1, 1)),
            Object([0], (2, 1)),
            Object([1], (1, 1)),
            Object([1], (2, 1)),
        ]
        val2 = Dict(
            0 => [
            Object([0], (1, 1)),
            Object([0], (2, 1)),
            ],
            1 => [
            Object([1], (1, 1)),
            Object([1], (2, 1)),
            ]
        )
        @test get_complexity(val1) > get_complexity(val2)
        val1 = [
            Object([0], (1, 1)),
            Object([1], (2, 1)),
        ]
        val2 = Dict(
            0 => [
            Object([0], (1, 1)),
            ],
            1 => [
            Object([1], (2, 1)),
            ]
        )
        @test get_complexity(val1) < get_complexity(val2)
    end

    @testset "similar objects" begin
        a = [
            Object([1], (1, 3)),
            Object([-1 0 -1; 0 0 0; 0 0 0], (1, 1)),
            Object([1], (1, 1)),
        ]
        b = [
            Object([-1 0 -1; 0 0 0; 0 0 0], (1, 1)),
            Object([1], (1, 3)),
            Object([1], (1, 1)),
        ]
        @test get_complexity(a) == get_complexity(b)
        @test get_complexity(a) == 64.11189875339844
    end

    @testset "generability" begin
        items = [1, 2, 3, 4]
        @test get_generability(items) == 1

        items = [5, 2, 3, 4]
        @test get_generability(items) == 1

        items = [2, 4, 6, 8]
        @test get_generability(items) == 4

        items = [(0, 0), (0, 1), (1, 0), (1, 1)]
        @test get_generability(items) == 1

        items = [(0, 0), (0, 1), (1, 0)]
        @test get_generability(items) == 2

        items = [(0, 0), (0, 1), (5, 0)]
        @test get_generability(items) == 10

        items = [true, false]
        @test get_generability(items) == 1

        items = [true]
        @test get_generability(items) == 2

        items = [(true, false), (true, true)]
        @test get_generability(items) == 1

        items = [(true, false), (false, true)]
        @test get_generability(items) == 1

        items = [(true, false), (false, true), (true, true, true)]
        @test get_generability(items) == 6

        items = [((0, 0), (1, 0)), ((0, 0), (0, 1))]
        @test get_generability(items) == 3

        items = [[1 1], fill(1, 2, 1)]
        @test get_generability(items) == 3

        items = [((0, 0), (1, 0)), ((0, 0), (0, 1)), ((0, 0), (1, 0), (2, 0))]
        @test get_generability(items) == 6

        items = [[1 1], fill(1, 2, 1), [1 1 1]]
        @test get_generability(items) == 6

        items = [
            Object([0 0], (1, 1)),
            Object([1 1], (1, 1))
        ]
        @test get_generability(items) == 3

        items = [
            Object([0 0], (1, 1)),
            Object([2 2], (1, 1))
        ]
        @test get_generability(items) == 8

        items = [
            Object([0 0], (1, 1)),
            Object([2 2; 2 -1], (5, 1)),
        ]
        @test get_generability(items) == 359

        items = [
            (false, false, true, false),
            (true, false, false, false),
            (false, true, false, false),
            (false, false, false, true)
        ]
        @test get_generability(items) == 1
    end

    @testset "mapper complexity" begin
        m = MapValues(
            "spatial_objects|grouped|0|single_value|border_alignment",
            "spatial_objects|grouped|0|first|splitted|step",
            Dict(
                (false, false, true, false) => (-1, 0),
                (true, false, false, false) => (1, 0),
                (false, true, false, false) => (0, 1),
                (false, false, false, true) => (0, -1)
            )
        )
        @test m.complexity == 65.190125

        m = MapValues(
            "spatial_objects|distance",
            "spatial_objects|grouped|0|step|to_value",
            Dict(
                (0, 2) => (0, 4),
                (0, 3) => (0, 6),
                (2, 0) => (4, 0),
                (4, 0) => (8, 0)
            )
        )
        @test m.complexity == 303.3
        @test get_generability(keys(m.match_pairs)) == 17

        m = MapValues(
            "output",
            "input|bgr_grid",
            Dict{Any,Any}(
                [-1 -1 -1; -1 2 2; -1 2 2] => [1 0 0; 0 0 0; 0 0 0],
                [-1 -1 2 2 -1 -1 -1; -1 -1 2 2 -1 -1 -1; 2 2 -1 -1 -1 -1 -1; 2 2 -1 2 2 -1 -1; -1 -1 -1 2 2 -1 -1; 2 2 -1 -1 -1 -1 -1; 2 2 -1 -1 -1 -1 -1] => [1 0 1; 0 1 0; 1 0 0],
                [-1 -1 -1 -1 -1 -1 -1; -1 2 2 -1 -1 -1 -1; -1 2 2 -1 2 2 -1; -1 -1 -1 -1 2 2 -1; -1 -1 2 2 -1 -1 -1; -1 -1 2 2 -1 -1 -1; -1 -1 -1 -1 -1 -1 -1] => [1 0 0; 0 1 0; 1 0 0],
                [-1 -1 -1 -1 -1 -1 -1; -1 -1 2 2 -1 2 2; -1 -1 2 2 -1 2 2; -1 -1 -1 -1 -1 -1 -1; 2 2 -1 2 2 -1 -1; 2 2 -1 2 2 -1 -1; -1 -1 -1 -1 -1 -1 -1] => [1 0 1; 0 1 0; 1 0 0],
                [2 2 -1 -1 -1; 2 2 -1 -1 -1; -1 -1 -1 -1 -1; -1 -1 -1 -1 -1; -1 -1 -1 -1 -1] => [1 0 0; 0 0 0; 0 0 0],
                [-1 -1 -1 -1 2 2 -1; -1 2 2 -1 2 2 -1; -1 2 2 -1 -1 -1 -1; -1 -1 -1 -1 -1 2 2; 2 2 -1 -1 -1 2 2; 2 2 -1 2 2 -1 -1; -1 -1 -1 2 2 -1 -1] => [1 0 1; 0 1 0; 1 0 1],
                [-1 -1 -1 -1 -1 -1; -1 2 2 -1 -1 -1; -1 2 2 -1 2 2; -1 -1 -1 -1 2 2; -1 -1 -1 -1 -1 -1; -1 -1 -1 -1 -1 -1] => [1 0 0; 0 0 0; 1 0 0],
                [-1 -1 -1 -1 -1; -1 2 2 -1 -1; -1 2 2 -1 -1; -1 -1 -1 2 2; -1 -1 -1 2 2] => [1 0 0; 0 0 0; 1 0 0]
            )
        )
        @test m.generability == 994

        m = MapValues(
            "output|grid|bgr_grid",
            "input|grid|spatial_objects",
            Dict{Any,Any}(
                [
                    Object([0 0 0 0 0 0 0; 0 -1 -1 0 0 0 0; 0 -1 -1 0 -1 -1 0; 0 0 0 0 -1 -1 0; 0 0 -1 -1 0 0 0; 0 0 -1 -1 0 0 0; 0 0 0 0 0 0 0], (1, 1)),
                    Object([2 2; 2 2], (2, 2)),
                    Object([2 2; 2 2], (3, 5)),
                    Object([2 2; 2 2], (5, 3))
                ] => [1 -1 -1; -1 1 -1; 1 -1 -1],
                [
                    Object([0 0 0 0 0; 0 -1 -1 0 0; 0 -1 -1 0 0; 0 0 0 -1 -1; 0 0 0 -1 -1], (1, 1)),
                    Object([2 2; 2 2], (2, 2)),
                    Object([2 2; 2 2], (4, 4))
                ] => [1 -1 -1; -1 -1 -1; 1 -1 -1],
                [
                    Object([0 0 0; 0 -1 -1; 0 -1 -1], (1, 1)),
                    Object([2 2; 2 2], (2, 2))
                ] => [1 -1 -1; -1 -1 -1; -1 -1 -1],
                [
                    Object([0 0 0 0 0 0 0; 0 0 -1 -1 0 -1 -1; 0 0 -1 -1 0 -1 -1; 0 0 0 0 0 0 0; -1 -1 0 -1 -1 0 0; -1 -1 0 -1 -1 0 0; 0 0 0 0 0 0 0], (1, 1)),
                    Object([2 2; 2 2], (2, 3)),
                    Object([2 2; 2 2], (2, 6)),
                    Object([2 2; 2 2], (5, 1)),
                    Object([2 2; 2 2], (5, 4))
                ] => [1 -1 1; -1 1 -1; 1 -1 -1],
                [
                    Object([0 0 0 0 -1 -1 0; 0 -1 -1 0 -1 -1 0; 0 -1 -1 0 0 0 0; 0 0 0 0 0 -1 -1; -1 -1 0 0 0 -1 -1; -1 -1 0 -1 -1 -1 -1; 0 0 0 -1 -1 -1 -1], (1, 1)),
                    Object([2 2; 2 2], (1, 5)),
                    Object([2 2; 2 2], (2, 2)),
                    Object([2 2; 2 2], (4, 6)),
                    Object([2 2; 2 2], (5, 1)),
                    Object([2 2; 2 2], (6, 4)),
                    Object([0 0; 0 0], (6, 6))
                ] => [1 -1 1; -1 1 -1; 1 -1 1],
                [
                    Object([0 0; 0 0], (1, 1)),
                    Object([2 2; 2 2], (1, 3)),
                    Object([-1 -1 -1 -1 0 0 0; -1 -1 -1 -1 0 0 0; -1 -1 0 0 0 0 0; -1 -1 0 -1 -1 0 0; 0 0 0 -1 -1 0 0; -1 -1 0 0 0 0 0; -1 -1 0 0 0 0 0], (1, 1)),
                    Object([2 2; 2 2], (3, 1)),
                    Object([2 2; 2 2], (4, 4)),
                    Object([2 2; 2 2], (6, 1))
                ] => [1 -1 1; -1 1 -1; 1 -1 -1],
                [
                    Object([2 2; 2 2], (1, 1)),
                    Object([-1 -1 0 0 0; -1 -1 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0], (1, 1))
                ] => [1 -1 -1; -1 -1 -1; -1 -1 -1],
                [
                    Object([0 0 0 0 0 0; 0 -1 -1 0 0 0; 0 -1 -1 0 -1 -1; 0 0 0 0 -1 -1; 0 0 0 0 0 0; 0 0 0 0 0 0], (1, 1)),
                    Object([2 2; 2 2], (2, 2)),
                    Object([2 2; 2 2], (3, 5))
                ] => [1 -1 -1; -1 -1 -1; 1 -1 -1]
            )
        )
        @test m.generability == 1001

        m = MapValues(
            "output|grid|bgr_grid|spatial_objects|item3",
            "input|grid",
            Dict{Any,Any}(
                [0 0 0 0 0 0 0; 0 2 2 0 0 0 0; 0 2 2 0 2 2 0; 0 0 0 0 2 2 0; 0 0 2 2 0 0 0; 0 0 2 2 0 0 0; 0 0 0 0 0 0 0] => Object([1], (3, 1)),
                [0 0 0 0 2 2 0; 0 2 2 0 2 2 0; 0 2 2 0 0 0 0; 0 0 0 0 0 2 2; 2 2 0 0 0 2 2; 2 2 0 2 2 0 0; 0 0 0 2 2 0 0] => Object([1], (2, 2)),
                [0 0 2 2 0 0 0; 0 0 2 2 0 0 0; 2 2 0 0 0 0 0; 2 2 0 2 2 0 0; 0 0 0 2 2 0 0; 2 2 0 0 0 0 0; 2 2 0 0 0 0 0] => Object([1], (2, 2)),
                [0 0 0 0 0 0 0; 0 0 2 2 0 2 2; 0 0 2 2 0 2 2; 0 0 0 0 0 0 0; 2 2 0 2 2 0 0; 2 2 0 2 2 0 0; 0 0 0 0 0 0 0] => Object([1], (2, 2))
            )
        )
        @test m.generability == 998.0
    end
end

include("../src/solution.jl")
include("../src/complexity.jl")
using .SolutionOps:Solution, get_unmatched_complexity_score
using .Complexity:get_complexity

@testset "Complexity" begin
    @testset "ideal solution" begin
        @test get_unmatched_complexity_score(
                Solution([Dict(
                    "input" => zeros(Int, 1, 1),
                    "output" => zeros(Int, 1, 1)
                )])
            ) == 0
    end

    @testset "simple value" begin
        @test get_complexity(5) == 1
        @test get_complexity(123) == 1
    end

    @testset "tuple" begin
        @test get_complexity((1,)) == 4
        @test get_complexity((1, 2)) == 4.9
        @test get_complexity((1, 2, 234)) == 5.7075
    end

    @testset "list" begin
        @test get_complexity([1, 2]) == 6.9
        @test get_complexity([34, 234, 32]) == 7.7075
    end

    @testset "position" begin
        @test_broken get_complexity(Pos(0, 1)) == 4
    end

    @testset "shape" begin
        @test_broken get_complexity(Shape(Dict(Pos(0, 0) => 0))) == 10
        @test_broken get_complexity(Shape(Dict(Pos(0, 0) => 0, Pos(0, 1) => 0))) == 13.6
    end

    @testset "object" begin
        @test_broken get_complexity(make_object_single_color(0, (Pos(0, 0),), Pos(0, 0))) == 14
        @test_broken get_complexity(make_object_single_color(0, (Pos(0, 0), Pos(0, 1)), Pos(0, 0))) == 17.6
    end

    @testset "reshape" begin
        val1 = Set(
            make_object_single_color(0, (Pos(0, 0),), Pos(0, 0)),
            make_object_single_color(0, (Pos(0, 0),), Pos(1, 0)),
        )
        val2 = Shape(Dict(Pos(0, 0) => 0))
        val3 = Set(
            Pos(0, 0),
            Pos(1, 0)
        )
        @test_broken get_complexity(val1) == 31.599999999999998
        @test_broken get_complexity(val2) == 10
        @test_broken get_complexity(val3) == 12.6
        @test_broken get_complexity(val1) > get_complexity(val2) + get_complexity(val3)

        val1 = Set(
            make_object_single_color(0, (Pos(0, 0),), Pos(0, 0)),
        )
        val2 = Shape(Dict(Pos(0, 0) => 0))
        val3 = Set(
            Pos(0, 0),
        )
        @test_broken get_complexity(val1) == 19
        @test_broken get_complexity(val2) == 10
        @test_broken get_complexity(val3) == 9
        @test_broken get_complexity(val1) == get_complexity(val2) + get_complexity(val3)
    end

    @testset "dict" begin
        data = Dict(
            "a" => 12,
            "b" => 10
        )
        @test get_complexity(data) == 5
        data = Dict(
            "a" => make_object_single_color(0, (Pos(0, 0),), Pos(0, 0)),
            "b" => make_object_single_color(0, (Pos(0, 0),), Pos(0, 0)),
        )
        @test get_complexity(data) == 31
    end

    @testset "group" begin
        val1 = [
            make_object_single_color(0, (Pos(0, 0),), Pos(0, 0)),
            make_object_single_color(0, (Pos(0, 0),), Pos(1, 0)),
        ]
        val2 = Dict(
            0 => [
                make_object_single_color(0, (Pos(0, 0),), Pos(0, 0)),
                make_object_single_color(0, (Pos(0, 0),), Pos(1, 0)),
            ]
        )
        @test_broken get_complexity(val1) < get_complexity(val2)
        val1 = [
            make_object_single_color(0, (Pos(0, 0),), Pos(0, 0)),
            make_object_single_color(0, (Pos(0, 0),), Pos(1, 0)),
            make_object_single_color(1, (Pos(0, 0),), Pos(0, 0)),
            make_object_single_color(1, (Pos(0, 0),), Pos(1, 0)),
        ]
        val2 = Dict(
            0 => [
                make_object_single_color(0, (Pos(0, 0),), Pos(0, 0)),
                make_object_single_color(0, (Pos(0, 0),), Pos(1, 0)),
            ],
            1 => [
                make_object_single_color(1, (Pos(0, 0),), Pos(0, 0)),
                make_object_single_color(1, (Pos(0, 0),), Pos(1, 0)),
            ]
        )
        @test_broken get_complexity(val1) > get_complexity(val2)
        val1 = [
            make_object_single_color(0, (Pos(0, 0),), Pos(0, 0)),
            make_object_single_color(1, (Pos(0, 0),), Pos(1, 0)),
        ]
        val2 = Dict(
            0 => [
                make_object_single_color(0, (Pos(0, 0),), Pos(0, 0)),
            ],
            1 => [
                make_object_single_color(1, (Pos(0, 0),), Pos(1, 0)),
            ]
        )
        @test_broken get_complexity(val1) < get_complexity(val2)
    end

    @testset "similar objects" begin
        a = Set(
            make_object_single_color(1, (Pos(0, 0),), Pos(1, 3)),
            make_object_single_color(0, (Pos(0, 1), Pos(1, 0), Pos(1, 1), Pos(1, 2), Pos(2, 0), Pos(2, 1), Pos(2, 2)), Pos(1, 1)),
            make_object_single_color(1, (Pos(0, 0),), Pos(1, 1))
        )
        b = Set(
            make_object_single_color(0, (Pos(0, 1), Pos(1, 0), Pos(1, 1), Pos(1, 2), Pos(2, 0), Pos(2, 1), Pos(2, 2)), Pos(1, 1)),
            make_object_single_color(1, (Pos(0, 0),), Pos(1, 3)),
            make_object_single_color(1, (Pos(0, 0),), Pos(1, 1))
        )
        @test a == b
        @test get_complexity(a) == get_complexity(b)
        @test get_complexity(a) == 57.870772076093736
    end

end
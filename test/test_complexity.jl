using .Solutions: get_unmatched_complexity_score
using .Complexity: get_complexity
using .ObjectPrior: Object
using .PatternMatching: ObjectShape
using .DataTransformers: match_fields

@testset "Complexity" begin
    @testset "ideal solution" begin
        solution = make_dummy_solution([Dict("input" => zeros(Int, 1, 1), "output" => zeros(Int, 1, 1))], ["output"])
        solution = match_fields(solution)[1]
        @test get_unmatched_complexity_score(solution) == 13
    end

    @testset "simple value" begin
        @test get_complexity(_wrap_ints(5)) == 1
        @test get_complexity(_wrap_ints(123)) == 1
    end

    @testset "tuple" begin
        @test get_complexity(_wrap_ints((1,))) == 4
        @test get_complexity(_wrap_ints((1, 2))) == 4.95
        @test get_complexity(_wrap_ints((1, 2, 23))) == 5.85375
    end

    @testset "list" begin
        @test get_complexity(_wrap_ints([1, 2])) == 6.95
        @test get_complexity(_wrap_ints([34, 23, 32])) == 7.85375
    end

    @testset "shape" begin
        @test get_complexity(_wrap_ints(fill(0, 1, 1))) == 13
        @test get_complexity(_wrap_ints(fill(0, 1, 2))) == 20.6
        @test get_complexity(
            _wrap_ints(
                [
                    0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0
                    2 2 2 2 2 2 2 2 2 2
                    0 0 0 0 0 0 0 0 0 0
                    8 8 8 8 8 8 8 8 8 8
                    0 0 0 0 0 0 0 0 0 0
                    2 2 2 2 2 2 2 2 2 2
                    0 0 0 0 0 0 0 0 0 0
                    8 8 8 8 8 8 8 8 8 8
                    0 0 0 0 0 0 0 0 0 0
                    2 2 2 2 2 2 2 2 2 2
                    0 0 0 0 0 0 0 0 0 0
                    8 8 8 8 8 8 8 8 8 8
                    0 0 0 0 0 0 0 0 0 0
                    2 2 2 2 2 2 2 2 2 2
                    0 0 0 0 0 0 0 0 0 0
                    8 8 8 8 8 8 8 8 8 8
                    0 0 0 0 0 0 0 0 0 0
                    2 2 2 2 2 2 2 2 2 2
                    0 0 0 0 0 0 0 0 0 0
                    8 8 8 8 8 8 8 8 8 8
                    0 0 0 0 0 0 0 0 0 0
                ],
            ),
        ) == 1005.0028390805662
    end

    @testset "object" begin
        @test get_complexity(_wrap_ints(Object([0], (1, 1)))) == 11.45
        @test get_complexity(_wrap_ints(Object([0 1], (1, 1)))) == 15.25
    end

    @testset "reshape" begin
        val1 = _wrap_ints([Object([0], (1, 1)), Object([0], (2, 1))])
        val2 = _wrap_ints(ObjectShape(Object([0], (1, 1))))
        val3 = _wrap_ints([(1, 1), (2, 1)])
        @test get_complexity(val1) == 27.327499999999997
        @test get_complexity(val2) == 11.45
        @test get_complexity(val3) == 14.6525
        @test get_complexity(val1) > get_complexity(val2) + get_complexity(val3)

        val1 = _wrap_ints([Object([0], (1, 1))])
        val2 = _wrap_ints(ObjectShape(Object([0], (1, 1))))
        val3 = _wrap_ints([(1, 1)])
        @test get_complexity(val1) == 16.45
        @test get_complexity(val2) == 11.45
        @test get_complexity(val3) == 9.95
        @test get_complexity(val1) < get_complexity(val2) + get_complexity(val3)
    end

    @testset "dict" begin
        data = _wrap_ints(Dict("a" => 12, "b" => 10))
        @test get_complexity(data) == 5
        data = _wrap_ints(Dict("a" => Object([0], (1, 1)), "b" => Object([0], (2, 1))))
        @test get_complexity(data) == 25.9
    end

    @testset "group" begin
        val1 = _wrap_ints([Object([0], (1, 1)), Object([0], (2, 1))])
        val2 = _wrap_ints(Dict(0 => [Object([0], (1, 1)), Object([0], (2, 1))]))
        @test get_complexity(val1) < get_complexity(val2)
        val1 = _wrap_ints([Object([0], (1, 1)), Object([0], (2, 1)), Object([1], (1, 1)), Object([1], (2, 1))])
        val2 = _wrap_ints(
            Dict(0 => [Object([0], (1, 1)), Object([0], (2, 1))], 1 => [Object([1], (1, 1)), Object([1], (2, 1))]),
        )
        @test get_complexity(val1) > get_complexity(val2)
        val1 = _wrap_ints([Object([0], (1, 1)), Object([1], (2, 1))])
        val2 = _wrap_ints(Dict(0 => [Object([0], (1, 1))], 1 => [Object([1], (2, 1))]))
        @test get_complexity(val1) < get_complexity(val2)
    end

    @testset "similar objects" begin
        a = _wrap_ints([Object([1], (1, 3)), Object([-1 0 -1; 0 0 0; 0 0 0], (1, 1)), Object([1], (1, 1))])
        b = _wrap_ints([Object([-1 0 -1; 0 0 0; 0 0 0], (1, 1)), Object([1], (1, 3)), Object([1], (1, 1))])
        @test get_complexity(a) == get_complexity(b)
        @test get_complexity(a) == 56.97752375339843
    end

end

using .Solutions: get_unmatched_complexity_score
using .Complexity: get_complexity
using .ObjectPrior: Object

@testset "Complexity" begin
    @testset "ideal solution" begin
        @test get_unmatched_complexity_score(
            make_dummy_solution([Dict("input" => zeros(Int, 1, 1), "output" => zeros(Int, 1, 1))], []),
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
        @test get_complexity(
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
        ) == 505.0014195402831
    end

    @testset "object" begin
        @test get_complexity(Object([0], (1, 1))) == 13.95
        @test get_complexity(Object([0 1], (1, 1))) == 17.75
    end

    @testset "reshape" begin
        val1 = [Object([0], (1, 1)), Object([0], (2, 1))]
        val2 = fill(0, 1, 1)
        val3 = [(1, 1), (2, 1)]
        @test get_complexity(val1) == 32.2025
        @test get_complexity(val2) == 9
        @test get_complexity(val3) == 14.6525
        @test get_complexity(val1) > get_complexity(val2) + get_complexity(val3)

        val1 = [Object([0], (1, 1))]
        val2 = fill(0, 1, 1)
        val3 = [(1, 1)]
        @test get_complexity(val1) == 18.95
        @test get_complexity(val2) == 9
        @test get_complexity(val3) == 9.95
        @test get_complexity(val1) == get_complexity(val2) + get_complexity(val3)
    end

    @testset "dict" begin
        data = Dict("a" => 12, "b" => 10)
        @test get_complexity(data) == 5
        data = Dict("a" => Object([0], (1, 1)), "b" => Object([0], (2, 1)))
        @test get_complexity(data) == 30.9
    end

    @testset "group" begin
        val1 = [Object([0], (1, 1)), Object([0], (2, 1))]
        val2 = Dict(0 => [Object([0], (1, 1)), Object([0], (2, 1))])
        @test get_complexity(val1) < get_complexity(val2)
        val1 = [Object([0], (1, 1)), Object([0], (2, 1)), Object([1], (1, 1)), Object([1], (2, 1))]
        val2 = Dict(0 => [Object([0], (1, 1)), Object([0], (2, 1))], 1 => [Object([1], (1, 1)), Object([1], (2, 1))])
        @test get_complexity(val1) > get_complexity(val2)
        val1 = [Object([0], (1, 1)), Object([1], (2, 1))]
        val2 = Dict(0 => [Object([0], (1, 1))], 1 => [Object([1], (2, 1))])
        @test get_complexity(val1) < get_complexity(val2)
    end

    @testset "similar objects" begin
        a = [Object([1], (1, 3)), Object([-1 0 -1; 0 0 0; 0 0 0], (1, 1)), Object([1], (1, 1))]
        b = [Object([-1 0 -1; 0 0 0; 0 0 0], (1, 1)), Object([1], (1, 3)), Object([1], (1, 1))]
        @test get_complexity(a) == get_complexity(b)
        @test get_complexity(a) == 64.11189875339844
    end

end

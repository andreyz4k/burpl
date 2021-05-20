
using .ObjectPrior:find_objects,Object,draw_object!

@testset "Object Prior" begin
    @testset "find no objects" begin
        grid = [0 0; 0 0]
        @test find_objects(grid) == Set([
            Object([0 0; 0 0], (1, 1))
        ])
    end

    @testset "find single object" begin
        grid = [0 0; 0 1]
        @test find_objects(grid) == Set([
            Object(
                [0 0; 0 -1],
                (1, 1)
            ),
            Object(
                [1],
                (2, 2)
            )
        ])
    end

    @testset "find single big object" begin
        grid = [2 2 0 0 0; 2 2 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
        @test find_objects(grid) == Set([
            Object(
                [2 2; 2 2],
                (1, 1)
            ),
            Object(
               [-1 -1 0 0 0; -1 -1 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0],
               (1, 1)
            )
        ])
    end

    @testset "find several objects" begin
        grid = [0 0 0 0 0; 0 2 2 0 0; 0 2 2 0 0; 0 0 0 2 2; 0 0 0 2 2]
        @test find_objects(grid) == Set([
            Object(
                [0 0 0 0 0; 0 -1 -1 0 0; 0 -1 -1 0 0; 0 0 0 -1 -1; 0 0 0 -1 -1],
                (1, 1)
            ),
            Object(
                [2 2; 2 2],
                (2, 2)
            ),
            Object(
                [2 2; 2 2],
                (4, 4)
            )
        ])
    end

    @testset "find small objects" begin
        grid = [1 0 1; 0 0 0; 0 0 0]
        @test find_objects(grid) == Set([
            Object(
                [1],
                (1, 1)
            ),
            Object(
                [-1 0 -1; 0 0 0; 0 0 0],
                (1, 1)
            ),
            Object(
                [1],
                (1, 3)
            )
        ])
    end

    @testset "draw object" begin
        grid = [0 0 0; 0 0 0; 0 0 0]
        obj = Object([1], (1, 1))
        draw_object!(grid, obj)
        @test grid == [1 0 0; 0 0 0; 0 0 0]
    end
end

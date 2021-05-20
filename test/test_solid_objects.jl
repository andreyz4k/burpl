
using .Abstractors:create,SolidObjects
using .PatternMatching:Either,Option
using .ObjectPrior:Object

@testset "Solid Objects" begin
    @testset "get abstractor" begin
        solution = make_dummy_solution([
            Dict(
                "input|bgr_grid" => [2 2 -1 -1 -1; 2 2 -1 -1 -1; -1 -1 -1 -1 -1; -1 -1 -1 -1 -1; -1 -1 -1 -1 -1]
            ),
            Dict(
                "input|bgr_grid" => [-1 -1 -1 -1 -1; -1 2 2 -1 -1; -1 2 2 -1 -1; -1 -1 -1 2 2; -1 -1 -1 2 2]
            ),
            Dict(
                "input|bgr_grid" => [-1 -1 -1 -1 -1 -1 -1; -1 2 2 -1 -1 -1 -1; -1 2 2 -1 2 2 -1; -1 -1 -1 -1 2 2 -1; -1 -1 2 2 -1 -1 -1; -1 -1 2 2 -1 -1 -1; -1 -1 -1 -1 -1 -1 -1]
            ),
            Dict(
                "input|bgr_grid" => [-1 -1 -1 -1 -1 -1; -1 2 2 -1 -1 -1; -1 2 2 -1 2 2; -1 -1 -1 -1 2 2; -1 -1 -1 -1 -1 -1; -1 -1 -1 -1 -1 -1]
            ),
            Dict(
                "input|bgr_grid" => Either([
                    Option([-1 -1 -1; -1 2 2; -1 2 2], 6951943934144298334),
                    Option([0 0 0; 0 -1 -1; 0 -1 -1], 73827427852322294)
                ])
            ),
            Dict(
                "input|bgr_grid" => [-1 -1 -1 -1 -1 -1 -1; -1 -1 2 2 -1 2 2; -1 -1 2 2 -1 2 2; -1 -1 -1 -1 -1 -1 -1; 2 2 -1 2 2 -1 -1; 2 2 -1 2 2 -1 -1; -1 -1 -1 -1 -1 -1 -1]
            ),
            Dict(
                "input|bgr_grid" => Either([
                    Option([-1 -1 -1 -1 2 2 -1; -1 2 2 -1 2 2 -1; -1 2 2 -1 -1 -1 -1; -1 -1 -1 -1 -1 2 2; 2 2 -1 -1 -1 2 2; 2 2 -1 2 2 -1 -1; -1 -1 -1 2 2 -1 -1], 9403704079446607950),
                    Option([0 0 0 0 -1 -1 0; 0 -1 -1 0 -1 -1 0; 0 -1 -1 0 0 0 0; 0 0 0 0 0 -1 -1; -1 -1 0 0 0 -1 -1; -1 -1 0 -1 -1 0 0; 0 0 0 -1 -1 0 0], 11382730904763864679)
                ])
            ),
            Dict(
                "input|bgr_grid" => [-1 -1 2 2 -1 -1 -1; -1 -1 2 2 -1 -1 -1; 2 2 -1 -1 -1 -1 -1; 2 2 -1 2 2 -1 -1; -1 -1 -1 2 2 -1 -1; 2 2 -1 -1 -1 -1 -1; 2 2 -1 -1 -1 -1 -1]
            )
        ])
        @test create(SolidObjects(), solution, "input|bgr_grid") != []
    end

    @testset "process either" begin
        abs = SolidObjects("input|bgr_grid", true)
        data = make_taskdata(Dict{String,Any}(
            "input|bgr_grid" => Either([
                Option([-1 -1 -1; -1 2 2; -1 2 2], 6951943934144298334),
                Option([0 0 0; 0 -1 -1; 0 -1 -1], 73827427852322294)
            ])
        ))
        out_data = abs(data)
        @test out_data == Dict(
            "input|bgr_grid|spatial_objects" => Either([
                Option(Set{Object}([Object([2 2; 2 2], (2, 2))]), 6951943934144298334),
                Option(Set{Object}([Object([0 0 0; 0 -1 -1; 0 -1 -1], (1, 1))]), 73827427852322294)
            ]),
            "input|bgr_grid|grid_size" => (3, 3),
            "input|bgr_grid" => Either([
                Option([-1 -1 -1; -1 2 2; -1 2 2], 6951943934144298334),
                Option([0 0 0; 0 -1 -1; 0 -1 -1], 73827427852322294)
            ])
        )
    end
end

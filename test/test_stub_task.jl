

using .burpl.Runner: solve_task, validate_results

@testset "Stub tasks" begin
    @testset "compress list" begin
        task_info = Dict(
            "train" => Dict("input" => [[1], [1, 1], [1, 1, 1]], "output" => [[2], [2, 2], [2, 2, 2]]),
            "test" => Dict("input" => [[1, 1, 1, 1]], "output" => [[2, 2, 2, 2]]),
        )
        answers = solve_task(task_info, false)
        @test validate_results(task_info["test"], answers)
    end

    @testset "replace background" begin
        task_info = Dict(
            "train" => Dict(
                "input" => [
                    [0 0; 1 0],
                    [0 0; 2 0; 0 2],
                    [0 1 0; 1 1 0; 0 0 0],
                ],
                "output" => [
                    [3 3; 1 3],
                    [3 3; 2 3; 3 2],
                    [3 1 3; 1 1 3; 3 3 3],
                ]
            ),
            "test" => Dict(
                "input" => [[1 0 0 1; 0 0 2 1; 0 0 1 0; 2 0 1 0]],
                "output" => [[1 3 3 1; 3 3 2 1; 3 3 1 3; 2 3 1 3]]
            )
        )
        answers = solve_task(task_info, false)
        @test validate_results(task_info["test"], answers)
    end
end

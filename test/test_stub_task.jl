

using .burpl.Runner: solve_task, validate_results

@testset "Solve stub task" begin
    task_info = Dict(
        "train" => Dict(
            "input" => [
                [1], [1, 1], [1, 1, 1]
            ],
            "output" => [
                [2], [2, 2], [2, 2, 2]
            ]
        ),
        "test" => Dict(
            "input" => [[1, 1, 1, 1]],
            "output" => [[2, 2, 2, 2]]
        )
    )
    answers = solve_task(task_info, false)
    @test validate_results(task_info["test"], answers)
end

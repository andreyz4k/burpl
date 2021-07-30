module Runner
using ..DataStructures: create_finder
using ..Solve: solve

function solve_task(task_info::Dict, debug::Bool, early_stop = true::Bool)
    answers = []
    solution_finder =
        create_finder(Dict("input" => task_info["train"]["input"]), Dict("output" => task_info["train"]["output"]))
    solve(solution_finder)
    return answers
end

function validate_results(test_info::Vector, answers::Vector)::Bool
    for answer in answers
        if all(compare_grids(target["output"], out_grid) == 0 for (out_grid, target) in zip(answer, test_info))
            return true
        end
    end
    return false
end

function convert_grids(taskdef)
    Dict(
        "train" => Dict(
            "input" => [hcat(task["input"]...) for task in taskdef["train"]],
            "output" => [hcat(task["output"]...) for task in taskdef["train"]],
        ),
        "test" => Dict(
            "input" => [hcat(task["input"]...) for task in taskdef["test"]],
            "output" => [hcat(task["output"]...) for task in taskdef["test"]],
        ),
    )
end

using JSON

get_taskdef(fname) = convert_grids(JSON.parsefile(fname))

function solve_and_check(fname::String; debug = false)::Bool
    @info(split(split(fname, '/')[end], '.')[1])
    task_info = get_taskdef(fname)
    answers = solve_task(task_info, debug)
    return validate_results(task_info["test"], answers)
end

export solve_and_check

end

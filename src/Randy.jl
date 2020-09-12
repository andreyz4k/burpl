module Randy
using ArgParse
import JSON

include("solution.jl")
using .SolutionOps

function convert_grids(taskdata)
    Dict(
        "train" => [
            Dict(
                "input" => hcat(task["input"]...),
                "output" => hcat(task["output"]...),
            ) for task in taskdata["train"]
        ],
        "test" => [
            Dict(
                "input" => hcat(task["input"]...),
                "output" => hcat(task["output"]...),
            ) for task in taskdata["test"]
        ]
    )
end

function main()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--filename"
            help = "task file to solve"
            # arg_type = string
            default = "data/training/ff28f65a.json"
        "--debug"
            action = :store_true
    end
    parsed_args = parse_args(ARGS, s)
    taskdata = JSON.parsefile(parsed_args["filename"])
    # println(taskdata["train"][1])
    taskdata = convert_grids(taskdata)

    solution = generate_solution(taskdata["train"], split(split(parsed_args["filename"], '/')[end], '.')[1], parsed_args["debug"])
    println(solution)
    println(validate_solution(solution, taskdata["train"]))
    println(validate_solution(solution, taskdata["test"]))
end

main()

end




using ArgParse
import JSON
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

get_taskdata(fname) = convert_grids(JSON.parsefile(fname))

function main()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--filename"
            help = "task file to solve"
            # arg_type = string
            # default = "data/training/ff28f65a.json"
            default = "data/training/0a938d79.json"
        "--debug"
            action = :store_true
    end
    parsed_args = parse_args(ARGS, s)

    solution = get_solution(parsed_args["filename"], parsed_args["debug"])
    test_solution(solution, parsed_args["filename"])
end

function test_solution(solution, fname)
    println(solution)
    taskdata = get_taskdata(fname)
    res = (validate_solution(solution, taskdata["train"]), validate_solution(solution, taskdata["test"]))
    println(res)
    res
end

function get_solution(fname, debug=false)
    taskdata = get_taskdata(fname)
    generate_solution(taskdata["train"], split(split(fname, '/')[end], '.')[1], debug)
end

# main()

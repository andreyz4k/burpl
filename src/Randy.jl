module Randy
using ArgParse
import JSON

function generate_solution(train_data, fname, debug)
end

function validate_solution(solution, taskdata)
    
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

    solution = generate_solution(taskdata["train"], split(split(parsed_args["filename"], '/')[end], '.')[1], parsed_args["debug"])
    println(solution)
    println(validate_solution(solution, taskdata["train"]))
    println(validate_solution(solution, taskdata["test"]))
end

main()

end # module

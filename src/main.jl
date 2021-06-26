


using ArgParse
using .FindSolution
using .Solutions


function main()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--filename"
            help = "task file to solve"
            # arg_type = string
            default = "data/training/ff28f65a.json"
            # default = "data/training/0a938d79.json"
            # default = "data/training/0b148d64.json"
            # default = "data/training/39a8645d.json"
            # default = "data/training/6e02f1e3.json"
            # default = "data/training/72ca375d.json"
        "--debug"
            action = :store_true
    end
    parsed_args = parse_args(ARGS, s)
    is_solved = solve_and_check(parsed_args["filename"], parsed_args["debug"])
    if is_solved
        @info("Solved")
    else
        @info("Not solved")
    end
end

# main()

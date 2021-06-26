export FindSolution
module FindSolution
export solve_and_check

using ..DataTransformers:match_fields
using ..Solutions:Solution,get_unmatched_complexity_score,insert_operation,persist_updates,compare_grids


import ..Abstractors

get_next_operations(solution, key) =
    reduce(vcat, (Abstractors.create(op_class, solution, key)
                  for op_class in Abstractors.classes), init=[])

function get_new_solutions_for_input_key(solution, key)
    output = []
    if !haskey(solution.field_info, key)
        return []
    end

    interesting_source = all(in(solution.field_info[k].derived_from, solution.field_info[key].previous_fields) for k in solution.unfilled_fields)

    required_types = union([vcat([[t, Dict{Int64,t}] for t in solution.field_info[k].precursor_types]...) for k in solution.unfilled_fields]...)

    for (priority, abstractor) in get_next_operations(solution, key)
        new_solution = insert_operation(solution, abstractor.to_abstract)

        if any(haskey(new_solution.field_info, k) for k in abstractor.to_abstract.output_keys) &&
            !any(in(new_solution.field_info[k].type, required_types)
                 for k in abstractor.to_abstract.output_keys if haskey(new_solution.field_info, k))
            priority *= 4
        end

        if !interesting_source
            priority *= 8
        end

        if in(key, solution.input_transformed_fields)
            priority *= 2
        end

        if in(key, solution.used_fields)
            priority *= 4
        end

        if startswith(key, "projected|")
            priority *= 8
        end

        for matched_solution in match_fields(new_solution)
            pr = priority * get_unmatched_complexity_score(matched_solution) *
                matched_solution.score^1.5
            if length(matched_solution.unfilled_fields) < length(solution.unfilled_fields)
                pr /= 4
            end
            push!(output, (pr, persist_updates(matched_solution)))
        end
    end
    output
end

function get_new_solutions_for_unfilled_key(solution::Solution, key::String)
    output = []
    source_fields = [solution.field_info[k].derived_from for k in solution.unfilled_fields]
    priority_key = all(in(k, solution.field_info[solution.field_info[key].derived_from].previous_fields) for k in source_fields)
    # @info(key, " ", source_fields, " ", priority_key)
    # @info(solution.field_info[solution.field_info[key].derived_from])
    for (priority, abstractor) in get_next_operations(solution, key)
        new_solution = insert_operation(solution, abstractor.from_abstract, reversed_op=abstractor.to_abstract)

        if !priority_key
            priority *= 8
        end

        for matched_solution in match_fields(new_solution)
            pr = priority * get_unmatched_complexity_score(matched_solution) *
                matched_solution.score^1.5
            push!(output, (pr, persist_updates(matched_solution)))
        end
    end
    output
end


function get_new_solutions(solution::Solution, debug::Bool)::Array{Tuple{Float64,Solution}}
    new_solutions = Tuple{Float64,Solution}[]
    for key in solution.unfilled_fields
        append!(new_solutions, get_new_solutions_for_unfilled_key(solution, key))
    end
    if !isempty(solution.unfilled_fields)
        for key in union(solution.unused_fields, solution.used_fields, solution.input_transformed_fields)
            append!(new_solutions, get_new_solutions_for_input_key(solution, key))
        end
    end
    sort!(new_solutions, by=(ps -> ps[1]))
    if debug
        @info(solution)
        @info(new_solutions)
        readline(stdin)
    end
    return new_solutions
end


function is_subsolution(old_sol::Solution, new_sol::Solution)::Bool
    equals = true
    for (new_inp_vals, new_out_vals, old_inp_vals, old_out_vals,
         new_task_data, old_task_data) in
            zip(new_sol.inp_val_hashes, new_sol.out_val_hashes,
                old_sol.inp_val_hashes, old_sol.out_val_hashes,
                new_sol.taskdata, old_sol.taskdata)
        if !issubset(new_out_vals, old_out_vals) ||
                !issubset(new_inp_vals, old_inp_vals)
            return false
        end
        if !issetequal(keys(new_task_data), keys(old_task_data))
            equals = false
        end
    end
    if equals && old_sol != new_sol
        return false
    end
    return true
end

check_border(solution::Solution, border::Set)::Bool =
    all(!is_subsolution(border_sol, solution) for border_sol in border)

function update_border!(border::Set, solution::Solution)
    obsolete = []
    for border_sol in border
        if is_subsolution(solution, border_sol)
            push!(obsolete, border_sol)
        end
    end
    setdiff!(border, obsolete)
    push!(border, solution)
end


using DataStructures

using IterTools:imap
using Base.Iterators:flatten


function pop_solution(queue, visited, border)
    while !isempty(queue)
        (solution, i), pr = peek(queue)
        dequeue!(queue)
        if in(solution, visited)
            continue
        end
        push!(visited, solution)
        if check_border(solution, border)
            update_border!(border, solution)
            return solution, i, pr
        end
    end
end

function generate_solutions(taskdata::Array, debug::Bool)
    init_solution = Solution(taskdata)
    queue = PriorityQueue()
    visited = Set()
    border = Set()
    enqueue!(queue, (init_solution, 0), 0)

    return flatten(imap(0:500) do real_visited
        sol_tuple = pop_solution(queue, visited, border)
        if isnothing(sol_tuple)
            return []
        end
        solution, i, pr = sol_tuple

        @info((real_visited, length(border), length(queue), solution.score, pr, i))
        new_solutions = get_new_solutions(solution, debug)
        skipmissing(imap(new_solutions) do (priority, new_solution)
            if in(new_solution, visited) || !check_border(new_solution, border)
                return missing
            end
            new_error = new_solution.score
            if new_error > solution.score
                return missing
            end
            if new_error == 0
                @info("found")
                @info(new_solution)
                push!(visited, new_solution)
                update_border!(border, new_solution)
                return new_solution
            end
            i += 1
            new_priority = priority * (i + 1) / 2
            new_priority = min(new_priority, get(queue, (new_solution, i - 1), new_priority))
            queue[(new_solution, i - 1)] = new_priority
            return missing
        end)

    end)
end


function solve_task(task_info::Dict, debug::Bool, early_stop=true::Bool)
    answers = []
    for solution in generate_solutions(task_info["train"], debug)
        answer = [solution(task["input"]) for task in task_info["test"]]
        if !in(answer, answers)
            push!(answers, answer)
        end
        if length(answers) >= 3
            break
        end
        if early_stop
            if all(compare_grids(target["output"], out_grid) == 0 for (out_grid, target) in zip(answer, task_info["test"]))
                break
            end
        end
    end
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
        "train" => [
            Dict(
                "input" => hcat(task["input"]...),
                "output" => hcat(task["output"]...),
            ) for task in taskdef["train"]
        ],
        "test" => [
            Dict(
                "input" => hcat(task["input"]...),
                "output" => hcat(task["output"]...),
            ) for task in taskdef["test"]
        ]
    )
end

using JSON

get_taskdef(fname) = convert_grids(JSON.parsefile(fname))

function solve_and_check(fname::String, debug=false)::Bool
    @info(split(split(fname, '/')[end], '.')[1])
    task_info = get_taskdef(fname)
    answers = solve_task(task_info, debug)
    return validate_results(task_info["test"], answers)
end

end

export FindSolution
module FindSolution
export generate_solution

using ..DataTransformers:match_fields
using ..Solutions:Solution,get_unmatched_complexity_score,insert_operation


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
            if length(matched_solution.unfilled_fields) < length(solution.unfilled_fields)
                priority /= 4
            end
            push!(output,
                  (priority * get_unmatched_complexity_score(matched_solution) *
                   matched_solution.score^1.5, matched_solution))
        end
    end
    output
end

function get_new_solutions_for_unfilled_key(solution::Solution, key::String)
    output = []
    source_fields = [solution.field_info[k].derived_from for k in solution.unfilled_fields]
    priority_key = all(in(k, solution.field_info[solution.field_info[key].derived_from].previous_fields) for k in source_fields)
    # println(key, " ", source_fields, " ", priority_key)
    # println(solution.field_info[solution.field_info[key].derived_from])
    for (priority, abstractor) in get_next_operations(solution, key)
        new_solution = insert_operation(solution, abstractor.from_abstract, reversed_op=abstractor.to_abstract)

        if !priority_key
            priority *= 8
        end

        for matched_solution in match_fields(new_solution)
            push!(output,
                  (priority * get_unmatched_complexity_score(matched_solution) *
                   matched_solution.score^1.5, matched_solution))
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
        println(solution)
        println(new_solutions)
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

function generate_solution(taskdata::Array, fname::AbstractString, debug::Bool)
    # debug = true
    println(fname)
    init_solution = Solution(taskdata)
    queue = PriorityQueue()
    visited = Set()
    real_visited = 0
    border = Set()
    enqueue!(queue, (init_solution, 0), 0)
    best_solution = init_solution
    while !isempty(queue)
        (solution, i), pr = peek(queue)
        dequeue!(queue)
        if in(solution, visited)
            continue
        end
        push!(visited, solution)
        if !check_border(solution, border)
            continue
        end
        real_visited += 1
        update_border!(border, solution)
        println((real_visited, length(border), length(queue), solution.score, pr, i))
        # println((pr, i, solution))
        new_solutions = get_new_solutions(solution, debug)
        for (priority, new_solution) in new_solutions
            if in(new_solution, visited) || !check_border(new_solution, border)
                continue
            end
            new_error = new_solution.score
            if new_error > solution.score
                continue
            end
            # println((priority, new_error))
            if new_error == 0
                println((real_visited, length(queue)))
                return new_solution
            end
            i += 1
            if new_error < best_solution.score
                best_solution = new_solution
            end
            new_priority = priority * (i + 1) / 2
            new_priority = min(new_priority, get(queue, (new_solution, i - 1), new_priority))
            queue[(new_solution, i - 1)] = new_priority
        end
        if real_visited > 500
            break
        end
    end
    println((real_visited, length(queue)))
    # println(visited)
    return best_solution
end

end

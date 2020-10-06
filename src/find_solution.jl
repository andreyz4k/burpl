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
    # unfilled_data_types = set()
    # for key_info in solution.unfilled_fields.params.values()
    #     unfilled_data_types.update(key_info.precursor_data_types)
    #     unfilled_data_types.add(key_info.data_type)
    # end
    output = []
    for (priority, abstractor) in get_next_operations(solution, key)
        new_solution = insert_operation(solution, abstractor.to_abstract)
        # for abs_key in abstractor.abs_keys
        #     if new_solution.get_key_data_type(abs_key) in unfilled_data_types
        #         priority /= 2
        #         break
        #     end
        # else
        #     priority *= 2
        # end

        if in(key, solution.input_transformed_fields)
            priority *= 4
        end

        if in(key, solution.used_fields)
            priority *= 8
        end

        if startswith(key, "projected|")
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

function get_new_solutions_for_unfilled_key(solution::Solution, key::String)
    output = []
    for (priority, abstractor) in get_next_operations(solution, key)
        # precursors = []
        # for key in abstractor.detailed_keys
        #     precursors.append(new_solution.unfilled_fields[key])
        # end

        new_solution = insert_operation(solution, abstractor.from_abstract, reversed_op=abstractor.to_abstract)

        # for abs_key in abstractor.abs_keys
        #     new_solution.unfilled_fields[abs_key].precursor_data_types = {
        #         data_type
        #         for precursor in precursors
        #         for data_type in {precursor.data_type}.union(precursor.precursor_data_types)
        #     }
        # end

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
    min_generality = Inf64
    while !isempty(queue)
        (solution, i), pr = peek(queue)
        dequeue!(queue)
        if in(solution, visited) || solution.generality >= min_generality
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
            if new_solution.generality >= min_generality || in(new_solution, visited) || !check_border(new_solution, border)
                continue
            end
            new_error = new_solution.score
            if new_error > solution.score
                continue
            end
            # println((priority, new_error))
            if new_error == 0
                min_generality = new_solution.generality
                if min_generality == 0.0
                    println((real_visited, length(queue)))
                    return new_solution
                else
                    println(min_generality, " ", new_solution)
                    best_solution = new_solution
                    continue
                end
            end
            i += 1
            if new_error < best_solution.score
                best_solution = new_solution
            end
            new_priority = priority * (i + 1) / 2
            new_priority = min(new_priority, get(queue, (new_solution, i - 1), new_priority))
            queue[(new_solution, i - 1)] = new_priority
        end
        if real_visited > 2000
            break
        end
    end
    println((real_visited, length(queue)))
    # println(visited)
    return best_solution
end

end


function get_match_transformers(taskdata::Array{Dict{String,Any}}, invalid_sources, key)
    result = []
    find_matches_funcs = [
        find_const,
        find_dependent_key,
        find_proportionate_key,
        find_shifted_key,
        find_proportionate_by_key,
        find_shifted_by_key,
        find_neg_shifted_by_key,
    ]
    for func in find_matches_funcs
        if length(result) == 1
            break
        end
        append!(result, func(taskdata, invalid_sources, key))
    end
    return result

end

using ..Solutions:Solution,insert_operation

function find_matched_fields(key, solution::Solution, get_transformers_func)
    new_solutions = []
    transformers = get_transformers_func(solution.taskdata, union(solution.unfilled_fields, solution.transformed_fields), key)
    for transformer in transformers
        new_solution = insert_operation(solution, transformer,
                                added_complexity=transformer.complexity)
        push!(new_solutions, new_solution)
    end
    return new_solutions
end

function exact_match_fields(solution::Solution)
    for key in solution.unfilled_fields
        new_solutions = find_matched_fields(key, solution, get_match_transformers)
        if length(new_solutions) != 1
            append!(new_solutions, find_matching_obj_group(key, solution))
        end
        if !isempty(new_solutions)
            return reduce(
                vcat,
                (exact_match_fields(new_solution) for new_solution in new_solutions),
                init=[]
            )
        end
    end
    return [solution]
end


function match_fields(solution::Solution)
    return exact_match_fields(solution)
end

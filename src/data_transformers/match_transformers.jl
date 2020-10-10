
function get_match_transformers(taskdata::Array{Dict{String,Any}}, field_info,  invalid_sources, key)
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
        append!(result, func(taskdata, field_info, invalid_sources, key))
    end
    return result

end

using ..Solutions:Solution,insert_operation

function find_matched_fields(key, solution::Solution, get_transformers_func)
    new_solutions = []
    transformers = get_transformers_func(solution.taskdata, solution.field_info, union(solution.unfilled_fields, solution.transformed_fields), key)
    for transformer in transformers
        new_solution = insert_operation(solution, transformer,
                                added_complexity=transformer.complexity)
        push!(new_solutions, new_solution)
    end
    return new_solutions
end

function match_fields(solution::Solution)
    for key in solution.unfilled_fields
        new_solutions = find_matched_fields(key, solution, get_match_transformers)
        if length(new_solutions) != 1
            append!(new_solutions, find_matching_obj_group(key, solution))
        end
        if !isempty(new_solutions)
            return reduce(
                vcat,
                (match_fields(new_solution) for new_solution in new_solutions),
                init=[]
            )
        end
    end
    return [solution]
end


function find_matching_for_key(taskdata::Vector{Dict{String,Any}}, field_info, invalid_sources::AbstractSet{String}, key::String,
                               init_func, filter_func, transformer_class, candidate_checker)
    result = []
    if !check_type(field_info[key].type, Union{Int64,Tuple{Int64,Int64}})
        return []
    end
    for input_key in keys(taskdata[1])
        if in(input_key, invalid_sources) || field_info[key].type != field_info[input_key].type
            continue
        end
        good = true
        candidates = []
        for task_data in taskdata
            if !haskey(task_data, input_key)
                good = false
                break
            end
            if !haskey(task_data, key)
                continue
            end
            input_value = task_data[input_key]
            out_value = task_data[key]
            if isempty(candidates)
                candidates = init_func(input_value, out_value, task_data, invalid_sources)
            end
            filter!(candidate -> filter_func(candidate, input_value, out_value, task_data), candidates)
            if isempty(candidates)
                good = false
                break
            end
        end
        if good
            append!(result, [transformer_class(key, input_key, candidate) for candidate in candidates
                             if candidate_checker(candidate, taskdata)])
        end
    end
    return result
end

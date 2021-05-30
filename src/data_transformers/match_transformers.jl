
using IterTools:imap
using Base.Iterators:flatten

function get_match_transformers(taskdata::Array{TaskData}, field_info,  invalid_sources, key)
    find_matches_funcs = [
        find_const,
        find_dependent_key,
        find_proportionate_key,
        find_shifted_key,
        find_proportionate_by_key,
        find_shifted_by_key,
        find_neg_shifted_by_key,
    ]
    return flatten(imap(func -> func(taskdata, field_info, invalid_sources, key), find_matches_funcs))
end

using ..Solutions:Solution,insert_operation

function find_matched_fields(key, solution::Solution)
    transformers = get_match_transformers(solution.taskdata, solution.field_info, union(solution.unfilled_fields, solution.transformed_fields), key)
    return flatten((imap(
        transformer -> insert_operation(solution, transformer,
                                        added_complexity=transformer.complexity), 
        transformers),
        find_matching_obj_group(key, solution)
    ))
end


function match_fields(solution::Solution)
    for key in solution.unfilled_fields
        try
            matched_results = Dict()
            valid_solutions_count = prod(length(unpack_value(task[key])) for task in solution.taskdata if haskey(task, key))
            iter = find_matched_fields(key, solution)
            state = ()
            counter = 0
            while length(matched_results) < valid_solutions_count
                next = iterate(iter, state)
                if isnothing(next)
                    break
                end
                counter += 1
                new_solution, state = next
                key_result = [task[key] for task in new_solution.taskdata]
                if !haskey(matched_results, key_result) 
                    matched_results[key_result] = new_solution
                end
            end
            if !isempty(matched_results)
                return reduce(
                vcat,
                (match_fields(new_solution) for (_, new_solution) in matched_results),
                init=[]
            )
            end
        catch
            println(solution)
            # println(solution.taskdata)
            rethrow()
        end
    end
    return [solution]
end


function find_matching_for_key(taskdata::Vector{TaskData}, field_info, invalid_sources::AbstractSet{String}, key::String,
                               init_func, filter_func, transformer_class)
    if !check_type(field_info[key].type, Union{Int64,Tuple{Int64,Int64}})
        return []
    end
    upd_keys = updated_keys(taskdata)
    flatten(imap(keys(taskdata[1])) do input_key
        if in(input_key, invalid_sources) || field_info[key].type != field_info[input_key].type || 
                (!in(key, upd_keys) && !in(input_key, upd_keys))
            return []
        end
        candidates = []
        for task_data in taskdata
            if !haskey(task_data, input_key)
                return []
            end
            if !haskey(task_data, key)
                continue
            end
            input_value = task_data[input_key]
            out_value = task_data[key]
            if isempty(candidates)
                candidates = init_func(input_value, out_value)
            end
            filter!(candidate -> filter_func(candidate, input_value, out_value, task_data), candidates)
            if isempty(candidates)
                return []
            end
        end
        return [transformer_class(key, input_key, candidate) for candidate in candidates]
    end)
end

function find_matching_for_key(taskdata::Vector{TaskData}, field_info, invalid_sources::AbstractSet{String}, key::String,
                               init_func, filter_func, transformer_class, candidate_checker)
    if !check_type(field_info[key].type, Union{Int64,Tuple{Int64,Int64}})
        return []
    end
    upd_keys = updated_keys(taskdata)
    flatten(imap(keys(taskdata[1])) do input_key
        if in(input_key, invalid_sources) || field_info[key].type != field_info[input_key].type
            return []
        end
        need_updated_candidates = !in(key, upd_keys) && !in(input_key, upd_keys)
        candidates = []
        for task_data in taskdata
            if !haskey(task_data, input_key)
                return []
            end
            if !haskey(task_data, key)
                continue
            end
            input_value = task_data[input_key]
            out_value = task_data[key]
            if isempty(candidates)
                candidates = init_func(input_key, field_info, task_data, invalid_sources)
                if need_updated_candidates
                    candidates = filter(k-> in(k, upd_keys), candidates)
                end
            end
            filter!(candidate -> filter_func(candidate, input_value, out_value, task_data), candidates)
            if isempty(candidates)
                return []
            end
        end
        return [transformer_class(key, input_key, candidate) for candidate in candidates
                if candidate_checker(candidate, input_key, taskdata)]
    end)
end

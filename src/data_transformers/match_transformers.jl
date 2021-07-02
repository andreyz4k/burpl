
using IterTools: imap
using Base.Iterators: flatten

function get_match_transformers(taskdata::TaskData, field_info, invalid_sources, key)
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

using ..Solutions: Solution, insert_operation

function find_matched_fields(key, solution::Solution)
    transformers = get_match_transformers(
        solution.taskdata,
        solution.field_info,
        union(solution.unfilled_fields, solution.transformed_fields),
        key,
    )
    return flatten((
        imap(
            transformer -> insert_operation(solution, transformer, added_complexity = transformer.complexity),
            transformers,
        ),
        find_matching_obj_group(key, solution),
    ))
end


function match_fields(solution::Solution)
    for key in solution.unfilled_fields
        try
            matched_results = Dict()
            valid_solutions_count =
                prod(length(unpack_value(value)) for value in solution.taskdata[key] if !ismissing(value))
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
                if !haskey(matched_results, new_solution.taskdata[key])
                    matched_results[new_solution.taskdata[key]] = new_solution
                end
            end
            if !isempty(matched_results)
                return reduce(vcat, (match_fields(new_solution) for (_, new_solution) in matched_results), init = [])
            end
        catch
            @info(solution)
            # @info(solution.taskdata)
            rethrow()
        end
    end
    return [solution]
end


function find_matching_for_key(
    taskdata::TaskData,
    field_info,
    invalid_sources::AbstractSet{String},
    key::String,
    init_func,
    filter_func,
    transformer_class,
)
    if !check_type(field_info[key].type, Union{Int64,Tuple{Int64,Int64}})
        return []
    end
    upd_keys = updated_keys(taskdata)
    flatten(
        imap(keys(taskdata)) do input_key
            if in(input_key, invalid_sources) ||
               field_info[key].type != field_info[input_key].type ||
               (!in(key, upd_keys) && !in(input_key, upd_keys))
                return []
            end
            candidates = []
            for (input_value, out_value) in zip(taskdata[input_key], taskdata[key])
                if ismissing(input_value)
                    return []
                end
                if ismissing(out_value)
                    continue
                end
                if isempty(candidates)
                    candidates = init_func(input_value, out_value)
                end
                filter!(candidate -> filter_func(candidate, input_value, out_value), candidates)
                if isempty(candidates)
                    return []
                end
            end
            return [transformer_class(key, input_key, candidate) for candidate in candidates]
        end,
    )
end

function find_matching_for_key(
    taskdata::TaskData,
    field_info,
    invalid_sources::AbstractSet{String},
    key::String,
    init_func,
    filter_func,
    transformer_class,
    candidate_checker,
)
    if !check_type(field_info[key].type, Union{Int64,Tuple{Int64,Int64}})
        return []
    end
    upd_keys = updated_keys(taskdata)
    flatten(
        imap(keys(taskdata)) do input_key
            if in(input_key, invalid_sources) || field_info[key].type != field_info[input_key].type
                return []
            end
            need_updated_candidates = !in(key, upd_keys) && !in(input_key, upd_keys)
            candidates = init_func(input_key, field_info, taskdata, invalid_sources)
            if need_updated_candidates
                candidates = filter(k -> in(k, upd_keys), candidates)
            end
            if isempty(candidates)
                return []
            end
            res = []
            for candidate in candidates
                valid = true
                for (input_value, out_value, cand_value) in
                    zip(taskdata[input_key], taskdata[key], taskdata[candidate])
                    if ismissing(input_value)
                        return []
                    end
                    if ismissing(out_value)
                        continue
                    end
                    if ismissing(cand_value) || !filter_func(cand_value, input_value, out_value)
                        valid = false
                        break
                    end
                end
                if valid
                    push!(res, candidate)
                end
            end
            return [
                transformer_class(key, input_key, candidate) for
                candidate in res if candidate_checker(candidate, input_key, taskdata)
            ]
        end,
    )
end

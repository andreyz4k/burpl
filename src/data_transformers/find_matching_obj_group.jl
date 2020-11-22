
using ..Operations:MapValues

function unroll_groups(matches)
    if isempty(matches)
        return [[]]
    end
    out = []
    for value in matches[1]
        for tail in unroll_groups(view(matches, 2:length(matches)))
            push!(out, [value, tail...])
        end
    end
    out
end

function check_matching_group(input_value, output_value, candidates)
    options = []
    for (key, value) in input_value
        if check_match(value, output_value)
            push!(options, key)
        end
    end
    push!(candidates, options)
    return !isempty(options)
end

using ..Abstractors:Abstractor,SelectGroup

_check_group_type(::Type, ::Type) = false
_check_group_type(::Type{Dict{K,V}}, expected::Type) where {K,V} = V == expected

function _get_matching_transformers(taskdata::Vector{Dict{String,Any}}, field_info, invalid_sources::AbstractSet{String}, key::String)
    result = []
    if endswith(key, "|selected_group")
        return []
    end
    for input_key in keys(taskdata[1])
        if in(input_key, invalid_sources) ||
                !_check_group_type(field_info[input_key].type, field_info[key].type) ||
                any(!haskey(task, input_key) for task in taskdata) || 
                all(length(task[input_key]) <= 1 for task in taskdata)
            continue
        end
        good = true
        matching_groups = []
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
            if !check_matching_group(input_value, out_value, matching_groups)
                good = false
                break
            end
        end
        if good
            for group_keys in unroll_groups(matching_groups)
                key_name = key * "|selected_group"
                to_abs = MapValues(key_name, "output", Dict(task_data["output"] => value for (task_data, value) in zip(taskdata, group_keys)))
                from_abs = Abstractor(SelectGroup(), true, [input_key, key_name], [key, key * "|rejected"], String[])
                push!(result, (to_abstract = to_abs, from_abstract = from_abs))
            end
        end
    end
    return result
end


using ..Solutions:Solution,insert_operation

function find_matching_obj_group(key, solution::Solution)
    new_solutions = []
    transformers = _get_matching_transformers(solution.taskdata, solution.field_info, union(solution.unfilled_fields, solution.transformed_fields), key)
    for transformer in transformers
        new_solution = insert_operation(solution, transformer.from_abstract, reversed_op=transformer.to_abstract)
        push!(new_solutions, new_solution)
    end
    return new_solutions
end

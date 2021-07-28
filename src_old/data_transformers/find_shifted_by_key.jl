
using ..Operations: IncByParam

_init_param_keys(input_key, field_info, task_data, invalid_sources) =
    collect(skipmissing(imap(task_data) do (key, value)
        if in(key, invalid_sources)
            return missing
        end
        field_type = field_info[key].type
        if field_type == Int64 || field_type == Tuple{Int64,Int64}
            return key
        end
        if field_type == field_info[input_key].type
            if field_type <: Dict
                if keys(value) == keys(task_data[input_key])
                    return key
                end
            else
                return key
            end
        end
        missing
    end))

_shifted_key_filter(shift_key, input_value, output_value, task_data) =
    haskey(task_data, shift_key) &&
    check_match(apply_func(input_value, (x, y) -> x .+ y, task_data[shift_key]), output_value)

_check_effective_shift_key(shift_key, input_key, taskdata) =
    all(haskey(task_data, shift_key) for task_data in taskdata) && any(
        apply_func(task_data[input_key], (x, y) -> x .+ y, task_data[shift_key]) != task_data[input_key] for
        task_data in taskdata
    )

function find_shifted_by_key(taskdata::Vector{TaskData}, field_info, invalid_sources::AbstractSet{String}, key::String)
    find_matching_for_key(
        taskdata,
        field_info,
        invalid_sources,
        key,
        _init_param_keys,
        _shifted_key_filter,
        IncByParam,
        _check_effective_shift_key,
    )
end


using ..Operations:IncByParam

_init_shift_keys(input_key, field_info, task_data, invalid_sources) =
    [key for (key, value) in task_data if !in(key, invalid_sources) && (
        field_info[key].type == Int64 || 
        field_info[key].type == Tuple{Int64,Int64} || 
        field_info[key].type == field_info[input_key].type
     )]

_shifted_key_filter(shift_key, input_value, output_value, task_data) = haskey(task_data, shift_key) &&
                         check_match(apply_func(input_value, (x, y) -> x .+ y, task_data[shift_key]), output_value)

_check_effective_shift_key(shift_key, taskdata) = any(task_data[shift_key] != 0 for task_data in taskdata)

function find_shifted_by_key(taskdata::Vector{TaskData}, field_info, invalid_sources::AbstractSet{String}, key::String)
    find_matching_for_key(taskdata, field_info, union(
        invalid_sources,
        filter(k -> !in(k, invalid_sources) && !_check_effective_shift_key(k, taskdata), keys(taskdata[1]))
    ), key, _init_shift_keys, _shifted_key_filter, IncByParam, _check_effective_shift_key)
end

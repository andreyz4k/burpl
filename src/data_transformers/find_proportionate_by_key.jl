
using ..Operations:MultByParam

_init_factor_keys(_, _, task_data, invalid_sources) =
    [key for (key, value) in task_data if !in(key, invalid_sources) && isa(value, Union{Int64,Tuple{Int64,Int64}})]

_factor_key_filter(shift_key, input_value, output_value, task_data) = haskey(task_data, shift_key) &&
                         check_match(apply_func(input_value, (x, y) -> x .* y, task_data[shift_key]), output_value)

_check_effective_factor_key(shift_key, taskdata) = any(task_data[shift_key] != 1 for task_data in taskdata)

function find_proportionate_by_key(taskdata::Vector{TaskData}, field_info, invalid_sources::AbstractSet{String}, key::String)
    find_matching_for_key(taskdata, field_info, union(
        invalid_sources,
        filter(k -> !in(k, invalid_sources) && !_check_effective_factor_key(k, taskdata), keys(taskdata[1]))
    ), key, _init_factor_keys, _factor_key_filter, MultByParam, _check_effective_factor_key)
end

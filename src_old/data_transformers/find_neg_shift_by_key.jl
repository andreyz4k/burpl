
using ..Operations: DecByParam

_shifted_neg_key_filter(shift_key, input_value, output_value, task_data) =
    haskey(task_data, shift_key) &&
    check_match(apply_func(input_value, (x, y) -> x .- y, task_data[shift_key]), output_value)

find_neg_shifted_by_key(taskdata::Vector{TaskData}, field_info, invalid_sources::AbstractSet{String}, key::String) =
    find_matching_for_key(
        taskdata,
        field_info,
        invalid_sources,
        key,
        _init_param_keys,
        _shifted_neg_key_filter,
        DecByParam,
        _check_effective_shift_key,
    )

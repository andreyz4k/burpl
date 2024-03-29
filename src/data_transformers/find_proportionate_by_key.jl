
using ..Operations: MultByParam


_factor_key_filter(shift_key, input_value, output_value, task_data) =
    haskey(task_data, shift_key) &&
    check_match(apply_func(input_value, (x, y) -> x .* y, task_data[shift_key]), output_value)

_check_effective_factor_key(shift_key, input_key, taskdata) =
    all(haskey(task_data, shift_key) for task_data in taskdata) && any(
        apply_func(task_data[input_key], (x, y) -> x .* y, task_data[shift_key]) != task_data[input_key] for
        task_data in taskdata
    )

function find_proportionate_by_key(
    taskdata::Vector{TaskData},
    field_info,
    invalid_sources::AbstractSet{String},
    key::String,
)
    find_matching_for_key(
        taskdata,
        field_info,
        invalid_sources,
        key,
        _init_param_keys,
        _factor_key_filter,
        MultByParam,
        _check_effective_factor_key,
    )
end

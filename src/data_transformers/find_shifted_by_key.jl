
using ..Operations: IncByParam

_init_shift_keys(input_key, field_info, taskdata, invalid_sources) = [
    key for (key, values) in taskdata if !in(key, invalid_sources) &&
    (all(!ismissing(val) for val in values)) &&
    (
        field_info[key].type == Int64 ||
        field_info[key].type == Tuple{Int64,Int64} ||
        (
            field_info[key].type == field_info[input_key].type &&
            (isa(values[1], Dict) ? keys(values[1]) == keys(taskdata[input_key][1]) : true)
        )
    )
]

_shifted_key_filter(shift_value, input_value, output_value) =
    check_match(apply_func(input_value, (x, y) -> x .+ y, shift_value), output_value)

_check_effective_shift_key(shift_key, input_key, taskdata) = any(
    apply_func(input_value, (x, y) -> x .+ y, shift_value) != input_value for
    (input_value, shift_value) in zip(taskdata[input_key], taskdata[shift_key])
)

function find_shifted_by_key(taskdata::TaskData, field_info, invalid_sources::AbstractSet{String}, key::String)
    find_matching_for_key(
        taskdata,
        field_info,
        invalid_sources,
        key,
        _init_shift_keys,
        _shifted_key_filter,
        IncByParam,
        _check_effective_shift_key,
    )
end

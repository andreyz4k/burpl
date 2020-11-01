
using ..Operations:IncParam

_get_diff_value(val1, val2) = val1 .- val2
_get_diff_value(val1::Vector, val2::Vector) = _get_diff_value(val1[1], val2[1])
function _get_diff_value(val1::Dict, val2::Dict)
    key, v1 = first(val1)
    if !haskey(val2, key)
        return nothing
    end
    _get_diff_value(v1, val2[key])
end

_init_shift(input_value, output_value, _, _) =
    filter(v -> !isnothing(v), [_get_diff_value(value, input_value) for value in unpack_value(output_value) if value != input_value])

_shifted_filter(shift, input_value, output_value, _) = !isnothing(common_value(apply_func(input_value, (x, y) -> x .+ y, shift), output_value))


find_shifted_key(taskdata::Vector{Dict{String,Any}}, field_info, invalid_sources::AbstractSet{String}, key::String) =
    find_matching_for_key(taskdata, field_info, invalid_sources, key, _init_shift, _shifted_filter, IncParam, (_, _) -> true)

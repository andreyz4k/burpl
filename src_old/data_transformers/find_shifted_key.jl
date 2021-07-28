
using ..Operations: IncParam

_get_diff_value(val1, val2) = val1 .- val2
_get_diff_value(val1::Vector, val2::Vector) = _get_diff_value(val1[1], val2[1])
function _get_diff_value(val1::Dict, val2::Dict)
    if !issetequal(keys(val1), keys(val2))
        return nothing
    end
    key, v1 = first(val1)
    cand = _get_diff_value(v1, val2[key])
    for (k, v1) in val1
        if _get_diff_value(v1, val2[k]) != cand
            return nothing
        end
    end
    cand
end

function _init_shift(input_value, output_value)
    input_value = unpack_value(input_value)[1]
    unique(
        filter(
            v -> !isnothing(v),
            [
                _get_diff_value(value, input_value) for
                value in unique(unpack_value(output_value)) if value != input_value
            ],
        ),
    )
end
_shifted_filter(shift, input_value, output_value, _) =
    check_match(apply_func(input_value, (x, y) -> x .+ y, shift), output_value)


find_shifted_key(taskdata::Vector{TaskData}, field_info, invalid_sources::AbstractSet{String}, key::String) =
    find_matching_for_key(taskdata, field_info, invalid_sources, key, _init_shift, _shifted_filter, IncParam)

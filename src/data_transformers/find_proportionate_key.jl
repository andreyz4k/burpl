
using ..Operations: MultParam

_init_factors(::Any...) = [-9, -8, -7, -6, -5, -4, -3, -2, -1, 2, 3, 4, 5, 6, 7, 8, 9]

_factor_filter(factor, input_value, output_value, _) =
    check_match(apply_func(input_value, (x, y) -> x .* y, factor), output_value)

find_proportionate_key(taskdata::Vector{TaskData}, field_info, invalid_sources::AbstractSet{String}, key::String) =
    find_matching_for_key(taskdata, field_info, invalid_sources, key, _init_factors, _factor_filter, MultParam)

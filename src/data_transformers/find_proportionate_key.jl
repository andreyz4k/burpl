
using ..Operations: MultParam

_init_factors(::Any...) = [
    OInt(-9),
    OInt(-8),
    OInt(-7),
    OInt(-6),
    OInt(-5),
    OInt(-4),
    OInt(-3),
    OInt(-2),
    OInt(-1),
    OInt(2),
    OInt(3),
    OInt(4),
    OInt(5),
    OInt(6),
    OInt(7),
    OInt(8),
    OInt(9),
]

_factor_filter(factor, input_value, output_value, _) =
    check_match(apply_func(input_value, (x, y) -> x .* y, factor), output_value)

find_proportionate_key(taskdata::Vector{TaskData}, field_info, invalid_sources::AbstractSet{String}, key::String) =
    find_matching_for_key(taskdata, field_info, invalid_sources, key, _init_factors, _factor_filter, MultParam)

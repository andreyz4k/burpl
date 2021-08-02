
struct ExtractBackground <: Abstractor end

abs_keys(::Type{ExtractBackground}) = ["bgr_value", "bgr_rem"]
abstracts_types(::Type{ExtractBackground}) = [Matrix]

using ..DataStructures: Color, make_either
_null_value(::Type) = missing
_null_value(::Type{Color}) = -1

_is_null_value(val, null_val) = ismissing(null_val) ? ismissing(val) : val == null_val

return_types(::Type{ExtractBackground}, type) = (type.parameters[1], type)


function to_abstract_inner(::Type{ExtractBackground}, type, matr_val)
    all_bgr_values = unique(matr_val)
    item_type = type.parameters[1]
    null_val = _null_value(item_type)
    options = []
    for bgr_value in all_bgr_values
        if _is_null_value(bgr_value, null_val)
            continue
        end
        bgr_rem = map(v -> _is_null_value(v, null_val) || v == bgr_value ? null_val : v, matr_val)
        push!(options, (bgr_value, bgr_rem))
    end
    if length(options) == 0
        return nothing
    end
    return make_either(options)
end

function from_abstract(::Type{ExtractBackground}, bgr_values_entry, bgr_rems_entry)
    result = []
    null_val = _null_value(bgr_values_entry.type)
    for (bgr_value, bgr_rem) in zip(bgr_values_entry.values, bgr_rems_entry.values)
        out_grid = map(v -> _is_null_value(v, null_val) ? bgr_value : v, bgr_rem)
        push!(result, out_grid)
    end

    return (Entry(bgr_rems_entry.type, result),)
end

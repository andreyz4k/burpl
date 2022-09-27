
struct ExtractBackground <: Abstractor end

abs_keys(::Type{ExtractBackground}) = ["bgr_value", "bgr_rem"]
abstracts_types(::Type{ExtractBackground}) = [Matrix]

using ..DataStructures: make_either, null_value, is_null_value

return_types(::Type{ExtractBackground}, type) = (type.parameters[1], type)


function to_abstract_inner(::Type{ExtractBackground}, type, matr_val)
    all_bgr_values = unique(matr_val)
    item_type = type.parameters[1]
    null_val = null_value(item_type)
    if any(is_null_value(v, null_val) for v in all_bgr_values)
        return nothing
    end
    options = []
    for bgr_value in all_bgr_values
        if is_null_value(bgr_value, null_val)
            continue
        end
        bgr_rem = map(v -> is_null_value(v, null_val) || v == bgr_value ? null_val : v, matr_val)
        push!(options, (bgr_value, bgr_rem))
    end
    return make_either(options)
end

function from_abstract(::Type{ExtractBackground}, bgr_values_entry, bgr_rems_entry)
    result = []
    null_val = null_value(bgr_values_entry.type)
    for (bgr_value, bgr_rem) in zip(bgr_values_entry.values, bgr_rems_entry.values)
        out_grid = map(v -> is_null_value(v, null_val) ? bgr_value : v, bgr_rem)
        push!(result, out_grid)
    end

    return (Entry(bgr_rems_entry.type, result),)
end

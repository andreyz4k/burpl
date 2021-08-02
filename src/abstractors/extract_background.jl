
struct ExtractBackground <: Abstractor end

abs_keys(::Type{ExtractBackground}) = ["bgr_value", "bgr_rem"]
abstracts_types(::Type{ExtractBackground}) = [Matrix]

using ..DataStructures: Color, make_either
_null_value(::Type) = missing
_null_value(::Type{Color}) = -1

function to_abstract(::Type{ExtractBackground}, value::Entry)
    bgr_values = []
    bgr_rems = []

    item_type = value.type.parameters[1]
    null_val = _null_value(item_type)

    for matr_val in value.values
        all_bgr_values = unique(matr_val)
        options = []
        for bgr_value in all_bgr_values
            bgr_rem = map(v -> v == bgr_value ? null_val : v, matr_val)
            push!(options, (bgr_value, bgr_rem))
        end
        bgr_value_matcher, bgr_rem_matcher = make_either(options)
        push!(bgr_values, bgr_value_matcher)
        push!(bgr_rems, bgr_rem_matcher)
    end
    return (Entry(item_type, bgr_values), Entry(value.type, bgr_rems))
end

function from_abstract(::Type{ExtractBackground}, bgr_values_entry, bgr_rems_entry)
    result = []
    null_val = _null_value(bgr_values_entry.type)
    for (bgr_value, bgr_rem) in zip(bgr_values_entry.values, bgr_rems_entry.values)
        out_grid = map(v -> (ismissing(null_val) ? ismissing(v) : v == null_val) ? bgr_value : v, bgr_rem)
        push!(result, out_grid)
    end

    return (Entry(bgr_rems_entry.type, result),)
end

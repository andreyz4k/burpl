
function get_match_transformers(taskdata::Array{Dict{String,Any}}, invalid_sources, key)
    result = []
    find_matches_funcs = [
        find_const,
        find_dependent_key,
        # TODO: fill
        find_proportionate_key,
        # find_shifted_matched_fields,
        # find_proportionate_by_key_matched_fields,
        # find_shifted_by_key_matched_fields
    ]
    for func in find_matches_funcs
        if length(result) == 1
            break
        end
        append!(result, func(taskdata, invalid_sources, key))
    end
    return result

end

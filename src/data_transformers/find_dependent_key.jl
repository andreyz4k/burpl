
using ..Operations: CopyParam

function find_dependent_key(taskdata::TaskData, field_info, invalid_sources::AbstractSet{String}, key::String)
    upd_keys = updated_keys(taskdata)
    skipmissing(
        imap(keys(taskdata)) do input_key
            if in(input_key, invalid_sources) ||
               field_info[key].type != field_info[input_key].type ||
               (!in(key, upd_keys) && !in(input_key, upd_keys))
                return missing
            end
            for (input_value, out_value) in zip(taskdata[input_key], taskdata[key])
                if ismissing(input_value)
                    return missing
                end
                if ismissing(out_value)
                    continue
                end
                if !check_match(input_value, out_value)
                    return missing
                end
            end
            return CopyParam(key, input_key)
        end,
    )
end


using ..Operations:CopyParam

function find_dependent_key(taskdata::Vector{TaskData}, field_info, invalid_sources::AbstractSet{String}, key::String)
    skipmissing(imap(keys(taskdata[1])) do input_key
        if in(input_key, invalid_sources) || field_info[key].type != field_info[input_key].type
            return missing
        end
        for task_data in taskdata
            if !haskey(task_data, input_key)
                return missing
            end
            if !haskey(task_data, key)
                continue
            end
            input_value = task_data[input_key]
            out_value = task_data[key]
            if !check_match(input_value, out_value)
                return missing
            end
        end
        return CopyParam(key, input_key)
    end)
end

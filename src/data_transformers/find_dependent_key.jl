
using ..Operations:CopyParam

function find_dependent_key(taskdata::Vector{Dict{String,Any}}, field_info, invalid_sources::AbstractSet{String}, key::String)
    result = []
    for input_key in keys(taskdata[1])
        if in(input_key, invalid_sources) || field_info[key].type != field_info[input_key].type
            continue
        end
        good = true
        for task_data in taskdata
            if !haskey(task_data, input_key)
                good = false
                break
            end
            if !haskey(task_data, key)
                continue
            end
            input_value = task_data[input_key]
            out_value = task_data[key]
            if !check_match(input_value, out_value)
                good = false
                break
            end
        end
        if good
            push!(result, CopyParam(key, input_key))
        end
    end
    return result
end

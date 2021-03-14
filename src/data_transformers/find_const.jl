
using ..Operations:SetConst

function find_const(taskdata::Vector{TaskData}, _, _, key::String)::Vector{SetConst}
    result = nothing
    for task_data in taskdata
        if !haskey(task_data, key)
            continue
        end
        if isnothing(result)
            result = task_data[key]
        end
        possible_value = common_value(result, task_data[key])
        if isnothing(possible_value)
            return []
        end
        result = possible_value
    end
    return [SetConst(key, value) for value in unpack_value(result)]
end

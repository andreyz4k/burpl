
using ..Operations: SetConst

function find_const(taskdata::TaskData, _, _, key::String)::Vector{SetConst}
    result = nothing
    if !in(key, updated_keys(taskdata))
        return []
    end
    for value in taskdata[key]
        if ismissing(value)
            continue
        end
        if isnothing(result)
            result = value
        end
        possible_value = common_value(result, value)
        if isnothing(possible_value)
            return []
        end
        result = possible_value
    end
    return [SetConst(key, value) for value in unpack_value(result)]
end

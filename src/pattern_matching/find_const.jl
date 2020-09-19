
function find_const(taskdata::Vector{Dict{String,Any}}, key::String)::Vector
    result = nothing
    for task_data in taskdata
        if !haskey(task_data, key)
            continue
        end
        possible_value = compare_values(result, task_data[key])
        if isnothing(possible_value)
            return []
        end
        result = possible_value
    end
    # if isa(result, Matcher)
    #     return result.get_values()
    # end
    return unpack_value(result)
end

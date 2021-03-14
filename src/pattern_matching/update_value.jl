
function fetch_value(data, keys)
    for key in keys
        data = get(data, key, nothing)
        if isnothing(data)
            break
        end
    end
    return data
end
using ..Taskdata:TaskData

function update_value(data::TaskData, key::String, value)::TaskData
    return update_value(data, [key], unpack_value(value)[1])
end

function update_value(data::TaskData, path_keys::Array, value)::TaskData
    return update_value(data, path_keys, value, fetch_value(data, path_keys))
end

function update_value(data::TaskData, path_keys::Array, value, ::Any)::TaskData
    if length(path_keys) == 1
        return merge(data, [path_keys[1] => value])
    end
    root_item = copy(data[path_keys[1]])
    item = root_item
    for key in path_keys[2:end - 1]
        item[key] = copy(item[key])
        item = item[key]
    end
    item[path_keys[end]] = value
    return merge(data, [path_keys[1] => root_item])
end

function update_value(data::TaskData, path_keys::Array, value, current_value::Dict)::TaskData
    for key in keys(current_value)
        data = update_value(data, vcat(path_keys, [key]), value[key], current_value[key])
    end
    data
end

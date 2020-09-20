
function fetch_value(data, keys)
    for key in keys
        data = get(data, key, nothing)
        if isnothing(data)
            break
        end
    end
    return data
end

function update_value(data::Dict, key::String, value)
    return update_value(data, [key], value)
end

function update_value(data::Dict, path_keys::Array, value)
    return update_value(data, path_keys, value, fetch_value(data, path_keys))
end

function update_value(data::Dict, path_keys::Array, value, ::Any)
    data = copy(data)
    item = data
    for key in path_keys[1:end - 1]
        item[key] = copy(item[key])
        item = item[key]
    end
    item[path_keys[end]] = value
    data
end

function update_value(data::Dict, path_keys::Array, value, current_value::Dict)
    for key in keys(current_value)
        data = update_value(data, vcat(path_keys, [key]), value[key], current_value[key])
    end
    data
end

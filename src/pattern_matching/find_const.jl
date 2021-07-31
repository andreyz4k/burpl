
using ..Operations: SetConst

common_value(v1, v2) = v1 == v2 ? v1 : nothing
all_options(val) = [val]

function find_const(branch, key)
    entry_value = branch[key]
    candidate = entry_value.values[1]
    for value in entry_value.values[2:end]
        candidate = common_value(candidate, value)
        if isnothing(candidate)
            return []
        end
    end
    return [SetConst(entry_value.type, val, key) for val in all_options(candidate)]
end

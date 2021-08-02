
using ..Operations: SetConst

all_options(val) = [val]
all_options(val::Either) = unique(vcat((all_options(option.value) for option in val.options)...))

function find_const(branch, key)
    entry_value = branch[key]
    candidates = all_options(entry_value.values[1])
    for value in view(entry_value.values, 2:length(entry_value.values))
        filter!(c -> check_match(c, value), candidates)
        if isempty(candidates)
            return []
        end
    end
    return [SetConst(entry_value.type, val, key) for val in candidates]
end

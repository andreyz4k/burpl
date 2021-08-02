
struct Option
    value::Any
    option_hash::Any
end

Base.show(io::IO, op::Option) = print(io, "Option(", op.value, ", ", op.option_hash, ")")

struct Either
    options::Vector{Option}
    connected_items::Vector
end

Base.show(io::IO, e::Either) = print(
    io,
    "Either([",
    vcat([[op, ", "] for op in e.options]...)[1:end-1]...,
    "], connected count: ",
    length(e.connected_items),
    ")",
)

function make_either(options)
    if length(options) == 1
        return options
    end
    grouped_options = [[] for _ = 1:length(options[1])]
    for option in options
        option_hash = hash(option)
        for (group, val) in zip(grouped_options, option)
            push!(group, Option(val, option_hash))
        end
    end
    results = [Either(group, []) for group in grouped_options]
    for (i, value) in enumerate(results)
        append!(value.connected_items, results[1:i-1])
        append!(value.connected_items, results[i+1:end])
    end
    return results
end

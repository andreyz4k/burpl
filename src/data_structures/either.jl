
struct Option
    value::Any
    option_hash::Any
end

Base.show(io::IO, op::Option) = print(io, "Option(", op.value, ", ", op.option_hash, ")")

struct Either
    options::Vector{Option}
end

Base.show(io::IO, e::Either) = print(
    io,
    "Either([",
    vcat([[op, ", "] for op in e.options]...)[1:end-1]...,
    "])",
)

function make_either(options)
    if length(options) == 1
        return options[1]
    end
    grouped_options = [[] for _ = 1:length(options[1])]
    for option in options
        option_hash = hash(option)
        for (group, val) in zip(grouped_options, option)
            push!(group, Option(val, option_hash))
        end
    end
    return tuple((Either(group) for group in grouped_options)...)
end

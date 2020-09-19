

struct Option
    value
    option_hash
end
Option(value) = Option(value, nothing)

Base.:(==)(a::Option, b::Option) = a.value == b.value && a.option_hash == b.option_hash
Base.show(io::IO, op::Option) = print(io, "Option(", op.value,
    (isnothing(op.option_hash) ? [] : [", ", op.option_hash])..., ")")

struct Either <: Matcher
    options::Array{Option}
    function Either(options::AbstractVector{Option})
        all_values = Set()
        for item in options
            push!(all_values, item.value)
        end
        if length(all_values) == 1
            for value in all_values
                return value
            end
        end
        return new(unique(options))
    end
end

Either(options::AbstractVector) = Either([Option(op) for op in options])

Base.:(==)(a::Either, b::Either) = issetequal(a.options, b.options)
Base.show(io::IO, e::Either) = print(io, "Either([", vcat([[op, ", "] for op in e.options]...)[1:end - 1]..., "])")

function make_either(keys, options)
    if length(options) == 1
        for option in options
            return Dict(k => v for (k, v) in zip(keys, option))
        end
    end
    if length(keys) > 1
        hashes = [hash(v) for v in options]
        result = Dict()
        for (i, key) in enumerate(keys)
            result[key] = Either([Option(op[i], h) for (op, h) in zip(options, hashes)])
        end
        return result
    else
        return Dict(keys[1] => Either(options))
    end
end

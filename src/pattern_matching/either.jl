

struct Option
    value
    option_hash
end

struct Either <: Matcher
    options::Array{Option}
end

function make_either(keys, options)
    if length(options) == 1
        for option in options
            return Dict(k => v for (k, v) in zip(keys, option))
        end
    end
    # if length(keys) > 1
    #     hashes = [hash(v) for v in options]
    #     result = Dict()
    #     for (i, key) in enumerate(keys)
    #         result[key] = cls.create_simple({cls.Option(op[i], h) for (op, h) in zip(options, hashes)})
    #     end
    #     return result
    # else
    #     return Dict(keys[1] => cls.create_simple(options))
    # end
end

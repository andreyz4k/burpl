

struct Option{T}
    value::Union{T,Matcher{T}}
    option_hash
end
Option(value) = Option(value, nothing)

Base.:(==)(a::Option, b::Option) = a.value == b.value && a.option_hash == b.option_hash
Base.hash(op::Option, h::UInt64) = hash(op.value, h) + hash(op.option_hash, h)
Base.show(io::IO, op::Option{T}) where {T} = print(io, "Option{", T, "}(", op.value,
    (isnothing(op.option_hash) ? [] : [", ", op.option_hash])..., ")")

struct Either{T} <: Matcher{T}
    options::Array{Option{T}}
    function Either(options::AbstractVector{Option{T}}) where {T}
        all_values = Set()
        for item in options
            push!(all_values, item.value)
        end
        if length(all_values) == 1
            for value in all_values
                return value
            end
        end
        return new{T}(unique(options))
    end
end

Either(options::AbstractVector) = Either([isa(op, Option) ? op : Option(op) for op in options])

Base.:(==)(a::Either, b::Either) = issetequal(a.options, b.options)
Base.hash(e::Either, h::UInt64) = hash(e.options, h)
Base.show(io::IO, e::Either{T}) where {T} = print(io, "Either{", T, "}([", vcat([[op, ", "] for op in e.options]...)[1:end - 1]..., "])")

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

function match(val1, val2::Either)
    valid_options = Option[]
    for option in val2.options
        m = common_value(val1, option.value)
        if !isnothing(m)
            if isa(m, Either)
                append!(valid_options, m.options)
            else
                push!(valid_options, Option(m))
            end
        end
    end
    if isempty(valid_options)
        return nothing
    else
        return Either(unique(valid_options))
    end
end


match(val1::Matcher, val2::Either) =
    invoke(match, Tuple{Any,Either}, val1, val2)

unpack_value(value::Either) = vcat([unpack_value(option.value) for option in value.options]...)

unwrap_matcher(value::Either) = [option.value for option in value.options]

update_value(data::Dict, path_keys::Array, value::Either, current_value::Either) =
    invoke(update_value, Tuple{Dict,Array,Any,Any}, data, path_keys, value, current_value)

function update_value(data::Dict, path_keys::Array, value, current_value::Either)
    for option in current_value.options
        if !isnothing(common_value(value, option.value))
            if !isnothing(option.option_hash)
                data = select_hash(data, option.option_hash)
            else
                data = invoke(update_value, Tuple{Dict,Array,Any,Any}, data, path_keys, option.value, current_value)
            end
            return update_value(data, path_keys, value)
        end
    end
end


select_hash(data::Dict, option_hash) =
    Dict{Any,Any}(key => select_hash(value, option_hash) for (key, value) in data)

function select_hash(data::Either, option_hash)
    new_options = Option[]
    for option in data.options
        if option.option_hash == option_hash
            return option.value
        end
        push!(new_options, Option(select_hash(option.value, option_hash), option.option_hash))
    end
    return Either(new_options)
end

select_hash(data, option_hash) = data

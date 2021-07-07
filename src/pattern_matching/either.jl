
_get_type(::T) where {T} = T
_get_type(val::Matcher) = _get_type(unwrap_matcher(val)[1])
struct Option{T}
    value::Union{T,Matcher{T}}
    option_hash::Any
    Option(v::T, op_hash) where {T} = new{_get_type(v)}(v, op_hash)
end
Option(value) = Option(value, nothing)

Base.:(==)(a::Option, b::Option) = a.value == b.value && a.option_hash == b.option_hash
Base.hash(op::Option, h::UInt64) = hash(op.value, h) + hash(op.option_hash, h)
Base.show(io::IO, op::Option{T}) where {T} =
    print(io, "Option{", T, "}(", op.value, (isnothing(op.option_hash) ? [] : [", ", op.option_hash])..., ")")

struct Either{T} <: Matcher{T}
    options::Array{Option{T}}
    function Either(options::AbstractVector{Option{T}}) where {T}
        if length(options) == 1
            return first(options).value
        end
        all_values = Set()
        for item in options
            push!(all_values, item.value)
        end
        if length(all_values) == 1
            return first(all_values)
        end
        return new{T}(options)
    end
end

Either(options::AbstractVector) = Either([isa(op, Option) ? op : Option(op) for op in options])

Base.:(==)(a::Either, b::Either) = issetequal(a.options, b.options)
Base.hash(e::Either, h::UInt64) = hash(e.options, h)
Base.show(io::IO, e::Either{T}) where {T} =
    print(io, "Either{", T, "}([", vcat([[op, ", "] for op in e.options]...)[1:end-1]..., "])")

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

function _common_value(val1, val2::Either)
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


_common_value(val1::Matcher, val2::Either) = invoke(_common_value, Tuple{Any,Either}, val1, val2)


_check_match(val1, val2::Either) = any(check_match(val1, option.value) for option in val2.options)

_check_match(val1::Matcher, val2::Either) = invoke(_check_match, Tuple{Any,Either}, val1, val2)


unpack_value(value::Either) = vcat([unpack_value(option.value) for option in value.options]...)

unwrap_matcher(value::Either) = [option.value for option in value.options]

using ..Taskdata: TaskData

update_value(data::TaskData, path_keys::Array, value::Either, current_value::Either)::TaskData =
    invoke(update_value, Tuple{TaskData,Array,Any,Any}, data, path_keys, value, current_value)

function update_value(data::TaskData, path_keys::Array, value, current_value::Either)::TaskData
    data = _update_value(data, path_keys[2], value, current_value)
    return invoke(update_value, Tuple{TaskData,Array,Any,Any}, data, path_keys, value, current_value)
end

function _update_value(data::TaskData, example_num, value, current_value::Either)::TaskData
    hashes_to_del = Set()
    matched_options = []
    for option in current_value.options
        if isnothing(common_value(value, option.value))
            if !isnothing(option.option_hash)
                push!(hashes_to_del, option.option_hash)
            end
        else
            push!(matched_options, option)
        end
    end
    while !isempty(hashes_to_del)
        data, hashes_to_del = drop_hashes(data, example_num, hashes_to_del)
    end
    for option in matched_options
        data = _update_value(data, example_num, value, option.value)
    end
    return data
end

_update_value(data::TaskData, example_num, value, current_value) = data


function drop_hashes(data::TaskData, example_num, hashes)
    data = copy(data)
    new_hashes = Set()
    for (key, value) in data
        modified, effective, mod_hashes = _drop_hashes(value[example_num], hashes)
        if effective
            data[key] = copy(value)
            data[key][example_num] = modified
            union!(new_hashes, mod_hashes)
        end
    end
    data, new_hashes
end

function _drop_hashes(data::Dict, hashes)
    effective = false
    result = nothing
    new_hashes = Set()
    past_keys = []
    for (key, value) in data
        modified, eff, mod_hashes = _drop_hashes(value, hashes)
        if !effective && eff
            result = Dict{Any,Any}(k => data[k] for k in past_keys)
            effective = true
        end
        if effective
            if eff
                result[key] = modified
                union!(new_hashes, mod_hashes)
            else
                result[key] = value
            end
        else
            push!(past_keys, key)
        end
    end
    if effective
        return result, effective, new_hashes
    else
        return data, effective, new_hashes
    end
end

function _drop_hashes(data::Vector, hashes)
    effective = false
    result = nothing
    new_hashes = Set()
    for (i, value) in enumerate(data)
        modified, eff, mod_hashes = _drop_hashes(value, hashes)
        if !effective && eff
            result = data[1:i-1]
            effective = true
        end
        if effective
            if eff
                push!(result, modified)
                union!(new_hashes, mod_hashes)
            else
                push!(result, value)
            end
        end
    end
    if effective
        return result, effective, new_hashes
    else
        return data, effective, new_hashes
    end
end

function _drop_hashes(data::Either, hashes)
    new_options = nothing
    effective = false
    new_hashes = Set()
    for (i, option) in enumerate(data.options)
        if in(option.option_hash, hashes)
            if !effective
                new_options = data.options[1:i-1]
            end
            union!(new_hashes, _all_hashes(option.value))
            effective = true
        else
            modified, eff, mod_hashes = _drop_hashes(option.value, hashes)
            if !effective && eff
                new_options = data.options[1:i-1]
                effective = true
            end
            if effective
                if eff
                    union!(new_hashes, mod_hashes)
                    if !isnothing(modified)
                        push!(new_options, Option(modified, option.option_hash))
                    end
                else
                    push!(new_options, option)
                end
            end
        end
    end
    if effective
        if isempty(new_options)
            return nothing, true, new_hashes
        end
        return Either(new_options), effective, new_hashes
    else
        return data, effective, new_hashes
    end
end

_drop_hashes(data, hashes) = data, false, Set()

function _all_hashes(data::Either)
    result = Set()
    for option in data.options
        if !isnothing(option.option_hash)
            push!(result, option.option_hash)
        end
        union!(result, _all_hashes(option.value))
    end
    return result
end

_all_hashes(::Any) = Set()

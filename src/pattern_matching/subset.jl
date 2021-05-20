

struct SubSet{T} <: Matcher{T}
    value::Vector
    SubSet(val::Set{S}) where S = new{Set{S}}([val])
    SubSet(val::Vector{S}) where S = new{Set{S}}([Set([v]) for v in val])
    SubSet{T}(val::Vector{T}) where T = new{T}(val)
    SubSet(val::Set{<:Matcher{S}}) where S = new{Set{S}}([val])
    SubSet(val::Vector{<:Matcher{S}}) where S = new{Set{S}}([Set([v]) for v in val])
end

Base.:(==)(a::SubSet, b::SubSet) = a.value == b.value
Base.hash(p::SubSet, h::UInt64) = hash(p.value, h)
Base.show(io::IO, p::SubSet{T}) where {T} = print(io, "SubSet{", T, "}(", p.value, ")")


_common_value(::Any, ::SubSet) = nothing

function _common_value(val1::T, val2::SubSet{T}) where T <: AbstractSet
    if length(val1) < sum([length(v) for v in val2.value])
        return nothing
    end
    return _merge_suborders([val1], val2.value)
end

function _common_value(val1::Vector{T}, val2::SubSet{Set{T}}) where T
    if length(val1) < sum([length(v) for v in val2.value])
        return nothing
    end
    return _merge_suborders([Set([v]) for v in val1], val2.value)
end

function _merge_suborders(val1::Vector{T}, val2::Vector{T}) where T <: AbstractSet
    result = T[]
    v1, v1_state = iterate(val1)
    v2, v2_state = iterate(val2)
    while true
        if isnothing(v1) || isempty(v1)
            v1_t = iterate(val1, v1_state)
            if !isnothing(v1_t)
                v1, v1_state = v1_t
            else
                v1 = nothing
            end
        end
        if isnothing(v2) || isempty(v2)
            v2_t = iterate(val2, v2_state)
            if !isnothing(v2_t)
                v2, v2_state = v2_t
            else
                v2 = nothing
            end
        end
        if isnothing(v1) && isnothing(v2)
            break
        end
        if isnothing(v1)
            push!(result, v2)
            v2 = nothing
            continue
        end
        if isnothing(v2)
            push!(result, v1)
            v1 = nothing
            continue
        end
        int = intersect(v1, v2)
        push!(result, int)
        v1 = setdiff(v1, int)
        v2 = setdiff(v2, int)
        if !isnothing(v1) && !isempty(v1) && !isnothing(v2) && !isempty(v2)
            return nothing
        end
    end
    return SubSet{T}(result)
end

function _common_value(val1::SubSet{T}, val2::SubSet{T}) where T <: AbstractSet
    return _merge_suborders(val1.value, val2.value)
end

_common_value(val1::Either, val2::SubSet) =
    invoke(_common_value, Tuple{Any,Either}, val2, val1)

_common_value(::Matcher, ::SubSet) = nothing


_check_match(::Any, ::SubSet) = false

_check_match(val1::SubSet, ::Any) = false
_check_match(val1::SubSet, val2::SubSet) = check_match(val1.value, val2)
_check_match(val1::SubSet, val2::Either) = check_match(val1.value, val2)
_check_match(val1::SubSet, ::Matcher) = false

function _check_match(val1::T, val2::SubSet{T}) where T <: AbstractSet
    for pref in val2.value, val in pref
        found = false
        for v1 in val1
            if check_match(v1, val)
                val1 = setdiff(val1, [v1])
                found = true
                break
            end
        end
        if !found
            return false
        end
    end
    return true
end

function _check_match(val1::Vector{T}, val2::SubSet{Set{T}}) where T
    i = 1
    for pref in val2.value
        while !isempty(pref)
            found = false
            if i > length(val1)
                return false
            end
            for val in pref
                if check_match(val1[i], val)
                    i += 1
                    pref = setdiff(pref, [val])
                    found = true
                    break
                end
            end
            if !found
                return false
            end
        end
    end
    return true
end

unpack_value(p::SubSet) = unpack_value([v for val in p.value for v in val])

unwrap_matcher(p::SubSet) = [Set(v for val in p.value for v in val)]

function update_value(data::TaskData, path_keys::Array, value::AbstractSet{T}, current_value::SubSet)::TaskData where T
    result = Set{T}()
    for pref in current_value.value, val in pref
        for v1 in value
            if check_match(v1, val)
                push!(result, v1)
                value = setdiff(value, [v1])
                break
            end
        end
    end
    return invoke(update_value, Tuple{TaskData,Array,Any,Any}, data, path_keys, result, current_value)
end

function update_value(data::TaskData, path_keys::Array, value::AbstractVector{T}, current_value::SubSet)::TaskData where T
    result = Set{T}(value[1:sum(length(pref) for pref in current_value.value)])
    return invoke(update_value, Tuple{TaskData,Array,Any,Any}, data, path_keys, result, current_value)
end

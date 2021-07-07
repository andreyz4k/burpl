

struct AuxValue{T} <: Matcher{T}
    value::Union{T,Matcher{T}}
    AuxValue(v::Matcher{T}) where {T} = new{T}(v)
    AuxValue(v::T) where {T} = new{T}(v)
end

Base.:(==)(a::AuxValue, b::AuxValue) = a.value == b.value
Base.hash(p::AuxValue, h::UInt64) = hash(p.value, h)
Base.show(io::IO, p::AuxValue{T}) where {T} = print(io, "AuxValue{", T, "}(", p.value, ")")

_common_value(val1::AuxValue{T}, val2::AuxValue{T}) where {T} =
    isa(val2.value, Matcher) ? nothing : common_value(val1.value, val2.value)
_common_value(val1::T, val2::AuxValue{T}) where {T} =
    isa(val2.value, Matcher) ? nothing : common_value(val1, val2.value)

check_match(::AuxValue, ::Any) = false

unpack_value(p::AuxValue) = isa(p.value, Matcher) ? [] : unpack_value(p.value)

unwrap_matcher(p::AuxValue) = [p.value]


_update_value(data::TaskData, example_num, value, current_value::AuxValue) = _update_value(data, example_num, value, current_value.value)

function _drop_hashes(data::AuxValue, hashes)
    modified, effective, mod_hashes = _drop_hashes(data.value, hashes)
    if isnothing(modified)
        return nothing, effective, mod_hashes
    end
    if effective
        AuxValue(modified), effective, mod_hashes
    else
        data, effective, mod_hashes
    end
end

_all_hashes(data::AuxValue) = _all_hashes(data.value)

apply_func(value::AuxValue, func, param) = apply_func(value.value, func, param)

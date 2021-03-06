

struct AuxValue{T} <: Matcher{T}
    value::T
end

Base.:(==)(a::AuxValue, b::AuxValue) = a.value == b.value
Base.hash(p::AuxValue, h::UInt64) = hash(p.value, h)
Base.show(io::IO, p::AuxValue) = print(io, "AuxValue(", p.value, ")")

match(val1::AuxValue{T}, val2::AuxValue{T}) where T <: Matcher = nothing
match(val1::Any, val2::AuxValue{T}) where T <: Matcher = nothing
match(val1::Matcher, val2::AuxValue{T}) where T <: Matcher = nothing
match(val1::AuxValue{T}, val2::AuxValue{T}) where T = common_value(val1.value, val2.value)
match(val1::T, val2::AuxValue{T}) where T = common_value(val1, val2.value)

check_match(::AuxValue, ::Any) = false

unpack_value(p::AuxValue) = unpack_value(p.value)

unwrap_matcher(p::AuxValue) = [p.value]

select_hash(data::AuxValue, option_hash) =
    AuxValue(select_hash(data.value, option_hash))

apply_func(value::AuxValue, func, param) = apply_func(value.value, func, param)

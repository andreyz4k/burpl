

struct OInt <: Integer
    v::Int8
end
OInt(v::OInt) = v

Base.hash(i::OInt, h::UInt64) = hash(i.v, h)
Base.show(io::IO, a::OInt) = print(io, a.v)

Base.:(==)(a::OInt, b::OInt) = a.v == b.v
Base.:(==)(a::OInt, b::Int) = a.v == b
Base.:(==)(a::Int, b::OInt) = a == b.v
Base.isless(a::OInt, b::OInt) = isless(a.v, b.v)
Base.:(<)(a::OInt, b::OInt) = a.v < b.v
Base.:(<)(a::Int, b::OInt) = a < b.v
Base.:(<)(a::OInt, b::Int) = a.v < b
Base.:(<=)(a::OInt, b::OInt) = a.v <= b.v
Base.:(<=)(a::Int, b::OInt) = a <= b.v
Base.:(<=)(a::OInt, b::Int) = a.v <= b

Base.:(:)(a::Int, b::OInt) = a:b.v
Base.:(:)(a::OInt, b::Int) = a.v:b


Base.:(+)(a::OInt, b::Int) = OInt(a.v + b)
Base.:(+)(a::Int, b::OInt) = OInt(a + b.v)
Base.:(+)(a::OInt, b::OInt) = OInt(a.v + b.v)
Base.:(-)(a::OInt, b::Int) = OInt(a.v - b)
Base.:(-)(a::Int, b::OInt) = OInt(a - b.v)
Base.:(-)(a::OInt, b::OInt) = OInt(a.v - b.v)
Base.:(*)(a::OInt, b::Int) = OInt(a.v * b)
Base.:(*)(a::Int, b::OInt) = OInt(a * b.v)
Base.:(*)(a::OInt, b::OInt) = OInt(a.v * b.v)
Base.div(a::OInt, b::OInt) = OInt(div(a.v, b.v))
Base.div(a::OInt, b::OInt, r::RoundingMode) = OInt(div(a.v, b.v, r))

Base.min(x::OInt, y::Int) = OInt(min(x.v, y))
Base.min(x::Int, y::OInt) = OInt(min(x, y.v))

Base.Int(i::OInt) = Int(i.v)

Base.zero(::OInt) = OInt(0)
Base.rem(a::OInt, b::OInt) = OInt(rem(a.v, b.v))

AnyInt() = OInt(127)

Base.convert(::Type{OInt}, v::Number) = OInt(v)
Base.convert(::Type{OInt}, v::OInt) = v

Base.transpose(x::OInt) = x

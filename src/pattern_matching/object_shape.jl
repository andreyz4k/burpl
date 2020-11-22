
using ..ObjectPrior:Object

struct ObjectShape{Object} <: Matcher{Object}
    object::Object
end

Base.:(==)(a::ObjectShape, b::ObjectShape) = a.object == b.object
Base.hash(p::ObjectShape, h::UInt64) = hash(p.object, h)
Base.show(io::IO, p::ObjectShape) = print(io, "ObjectShape(", p.object, ")")


match(::Any, ::ObjectShape) = nothing

function match(val1::Object, val2::ObjectShape)
    if val2.object.shape == val1.shape
        return val1
    end
    return nothing
end

function match(val1::ObjectShape, val2::ObjectShape)
    if val1.object.shape == val2.object.shape
        return val2
    end
    return nothing
end

match(val1::Either, val2::ObjectShape) =
    invoke(match, Tuple{Any,Either}, val2, val1)

match(::Matcher, ::ObjectShape) = nothing


_check_match(::Any, ::ObjectShape) = false

_check_match(val1::Object, val2::ObjectShape) =
    val2.object.shape == val1.shape

_check_match(val1::ObjectShape, val2) = check_match(val1.object, val2)
_check_match(val1::ObjectShape, val2::ObjectShape) = check_match(val1.object, val2)
_check_match(val1::ObjectShape, val2::Either) = check_match(val1.object, val2)


unpack_value(p::ObjectShape) = unpack_value(p.object)

unwrap_matcher(p::ObjectShape) = [p.object]

apply_func(value::ObjectShape, func, param) = apply_func(value.object, func, param)

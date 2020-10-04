
using ..ObjectPrior:Object

struct ObjectShape{Object} <: Matcher{Object}
    object::Object
end

Base.:(==)(a::ObjectShape, b::ObjectShape) = a.object == b.object
Base.hash(p::ObjectShape, h::UInt64) = hash(p.object, h)
Base.show(io::IO, p::ObjectShape) = print(io, "ObjectShape(", p.object, ")")


_common_value(val1, val2::ObjectShape) = nothing

function _common_value(val1::Object, val2::ObjectShape)
    if val2.object.shape == val1.shape
        return val1
    end
    return nothing
end

function _common_value(val1::ObjectShape, val2::ObjectShape)
    if val1.object.shape == val2.object.shape
        return val2
    end
    return nothing
end


_common_value(val1::Either, val2::ObjectShape) =
    invoke(_common_value, Tuple{Any,Either}, val2, val1)


match(val1::ObjectShape, val2) = nothing

function match(val1::ObjectShape, val2::Object)
    if val1.object.shape == val2.shape
        return val2
    end
    return nothing
end

function match(val1::ObjectShape, val2::ObjectShape)
    if val1.object.shape == val2.object.shape
        return val2
    end
    return nothing
end


match(val1::ObjectShape, val2::Either) =
    invoke(match, Tuple{Either,Matcher}, val2, val1)

unpack_value(p::ObjectShape) = [p.object]
unpack_value(p::AbstractVector{ObjectShape}) = [[v.object for v in p]]

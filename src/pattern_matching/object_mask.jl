
using ..ObjectPrior: Object, draw_object!

struct ObjectMask <: Matcher{Object}
    object::Object
end

Base.:(==)(a::ObjectMask, b::ObjectMask) = a.object == b.object
Base.hash(p::ObjectMask, h::UInt64) = hash(p.object, h)
Base.show(io::IO, p::ObjectMask) = print(io, "ObjectMask(", p.object, ")")

_common_value(::Any, ::ObjectMask) = nothing

function _common_value(val1::Object, val2::ObjectMask)
    if val1.position != val2.object.position || size(val1.shape) != size(val2.object.shape)
        return nothing
    end
    if all(v1 == v2 == -1 || (v1 != -1 && v2 != -1) for (v1, v2) in zip(val1.shape, val2.object.shape))
        return val1
    end
    return nothing
end

function _common_value(val1::ObjectMask, val2::ObjectMask)
    if val1.object.position != val2.object.position || size(val1.object.shape) != size(val2.object.shape)
        return nothing
    end
    if all(v1 == v2 == -1 || (v1 != -1 && v2 != -1) for (v1, v2) in zip(val1.object.shape, val2.object.shape))
        return val1
    end
    return nothing
end

_common_value(val1::Either, val2::ObjectMask) = invoke(_common_value, Tuple{Any,Either}, val2, val1)

_common_value(::Matcher, ::ObjectMask) = nothing



_check_match(::Any, ::ObjectMask) = false

_check_match(val1::Object, val2::ObjectMask) =
    val1.position == val2.object.position &&
    size(val1.shape) == size(val2.object.shape) &&
    all(v1 == v2 == -1 || (v1 != -1 && v2 != -1) for (v1, v2) in zip(val1.shape, val2.object.shape))

_check_match(val1::ObjectMask, val2) = check_match(val1.object, val2)
_check_match(val1::ObjectMask, val2::ObjectMask) = check_match(val1.object, val2)
_check_match(val1::ObjectMask, val2::Either) = check_match(val1.object, val2)

unpack_value(p::ObjectMask) = unpack_value(p.object)
options_count(p::ObjectMask) = options_count(p.object)

unwrap_matcher(p::ObjectMask) = [p.object]

apply_func(value::ObjectMask, func, param) = apply_func(value.object, func, param)

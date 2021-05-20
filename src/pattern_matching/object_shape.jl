
using ..ObjectPrior:Object

struct ObjectShape{Object} <: Matcher{Object}
    object::Object
end

struct ObjectsGroup <: Matcher{Set{Object}}
    objects::Set{Object}
end

Base.:(==)(a::ObjectShape, b::ObjectShape) = a.object == b.object
Base.hash(p::ObjectShape, h::UInt64) = hash(p.object, h)
Base.show(io::IO, p::ObjectShape) = print(io, "ObjectShape(", p.object, ")")

Base.:(==)(a::ObjectsGroup, b::ObjectsGroup) = a.objects == b.objects
Base.hash(p::ObjectsGroup, h::UInt64) = hash(p.objects, h)
Base.show(io::IO, p::ObjectsGroup) = print(io, "ObjectsGroup(", p.objects, ")")


_common_value(::Any, ::ObjectShape) = nothing

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

_common_value(::Matcher, ::ObjectShape) = nothing


_common_value(::Any, ::ObjectsGroup) = nothing

function _common_value(val1::Set{Object}, val2::ObjectsGroup)
    val2 = val2.objects

    function _inner(val1, val2, stride)
        if isempty(val1) && !isempty(val2)
            return nothing
        end
        for v1 in val1
            found = false
            for v2 in val2
                if v1.shape == v2.shape
                    str = isnothing(stride) ? v2.position .- v1.position : stride
                    if v1.position .+ str == v2.position && !isnothing(_inner(setdiff(val1, [v1]), setdiff(val2, [v2]), str))
                        found = true
                        break
                    end
                end
            end
            if !found
                return nothing
            end
        end
        return val1
    end

    return _inner(val1, val2, nothing)
end

function _common_value(val1::ObjectsGroup, val2::ObjectsGroup)
    return _common_value(val1.objects, val2)
end

_common_value(val1::Either, val2::ObjectsGroup) =
    invoke(_common_value, Tuple{Any,Either}, val2, val1)

_common_value(::Matcher, ::ObjectsGroup) = nothing


_check_match(::Any, ::ObjectShape) = false

_check_match(val1::Object, val2::ObjectShape) =
    val2.object.shape == val1.shape

_check_match(val1::ObjectShape, val2) = check_match(val1.object, val2)
_check_match(val1::ObjectShape, val2::ObjectShape) = check_match(val1.object, val2)
_check_match(val1::ObjectShape, val2::Either) = check_match(val1.object, val2)

_check_match(::Any, ::ObjectsGroup) = false

_check_match(val1::Set{Object}, val2::ObjectsGroup) =
    !isnothing(common_value(val1, val2))

_check_match(val1::ObjectsGroup, val2) = check_match(val1.objects, val2)
_check_match(val1::ObjectsGroup, val2::ObjectsGroup) = check_match(val1.objects, val2)
_check_match(val1::ObjectsGroup, val2::Either) = check_match(val1.objects, val2)
_check_match(val1::SubSet, ::ObjectsGroup) = false
_check_match(val1::ObjectsGroup, val2::SubSet) = check_match(val1.objects, val2)

unpack_value(p::ObjectShape) = unpack_value(p.object)

unwrap_matcher(p::ObjectShape) = [p.object]

apply_func(value::ObjectShape, func, param) = apply_func(value.object, func, param)

unpack_value(p::ObjectsGroup) = unpack_value(p.objects)

unwrap_matcher(p::ObjectsGroup) = [p.objects]

apply_func(value::ObjectsGroup, func, param) = apply_func(value.objects, func, param)

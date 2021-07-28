
using ..ObjectPrior: Object, draw_object!

struct ObjectShape{Object} <: Matcher{Object}
    object::Object
end

struct ObjectsGroup <: Matcher{Set{Object}}
    objects::Union{Set{Object},Matcher{Set{Object}}}
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

_common_value(val1::Either, val2::ObjectShape) = invoke(_common_value, Tuple{Any,Either}, val2, val1)

_common_value(::Matcher, ::ObjectShape) = nothing


_common_value(::Any, ::ObjectsGroup) = nothing

function _common_value(val1::Set{Object}, val2::ObjectsGroup)
    grid_1_min = reduce((a, b) -> min.(a, b), (obj.position for obj in val1), init = (100, 100))
    grid_1_size =
        reduce((a, b) -> max.(a, b), (obj.position .+ size(obj.shape) .- grid_1_min for obj in val1), init = (0, 0))
    grid_1 = fill(-1, grid_1_size)
    for obj in val1
        draw_object!(grid_1, Object(obj.shape, obj.position .- grid_1_min .+ (1, 1)))
    end

    for unpacked in unpack_value(val2.objects)
        grid_2_min = reduce((a, b) -> min.(a, b), (obj.position for obj in unpacked), init = (100, 100))
        grid_2_size = reduce(
            (a, b) -> max.(a, b),
            (obj.position .+ size(obj.shape) .- grid_2_min for obj in unpacked),
            init = (0, 0),
        )
        grid_2 = fill(-1, grid_2_size)
        for obj in unpacked
            draw_object!(grid_2, Object(obj.shape, obj.position .- grid_2_min .+ (1, 1)))
        end
        if grid_1 == grid_2
            return val1
        end
    end
    nothing
end

function _common_value(val1::ObjectsGroup, val2::ObjectsGroup)
    return _common_value(val1.objects, val2)
end

_common_value(val1::Either, val2::ObjectsGroup) = invoke(_common_value, Tuple{Any,Either}, val2, val1)

_common_value(::Matcher, ::ObjectsGroup) = nothing


_check_match(::Any, ::ObjectShape) = false

_check_match(val1::Object, val2::ObjectShape) = val2.object.shape == val1.shape

_check_match(val1::ObjectShape, val2) = check_match(val1.object, val2)
_check_match(val1::ObjectShape, val2::ObjectShape) = check_match(val1.object, val2)
_check_match(val1::ObjectShape, val2::Either) = check_match(val1.object, val2)

_check_match(::Any, ::ObjectsGroup) = false

_check_match(val1::Set{Object}, val2::ObjectsGroup) = !isnothing(common_value(val1, val2))

_check_match(val1::ObjectsGroup, val2) = check_match(val1.objects, val2)
_check_match(val1::ObjectsGroup, val2::ObjectsGroup) = check_match(val1.objects, val2)
_check_match(val1::ObjectsGroup, val2::Either) = check_match(val1.objects, val2)
_check_match(val1::SubSet, ::ObjectsGroup) = false
_check_match(val1::ObjectsGroup, val2::SubSet) = check_match(val1.objects, val2)

unpack_value(p::ObjectShape) = unpack_value(p.object)
options_count(p::ObjectShape) = options_count(p.object)

unwrap_matcher(p::ObjectShape) = [p.object]

apply_func(value::ObjectShape, func, param) = apply_func(value.object, func, param)

unpack_value(p::ObjectsGroup) = unpack_value(p.objects)
options_count(p::ObjectsGroup) = options_count(p.objects)

unwrap_matcher(p::ObjectsGroup) = [p.objects]

apply_func(value::ObjectsGroup, func, param) = apply_func(value.objects, func, param)

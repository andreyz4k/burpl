

struct GetPosition <: AbstractorClass end

@memoize abs_keys(::GetPosition) = ["objects", "positions"]

check_task_value(::GetPosition, value::Object, data, aux_values) = true
check_task_value(::GetPosition, value::AbstractVector{Object}, data, aux_values) = true


to_abstract_value(p::Abstractor, ::GetPosition, object::Object) =
    Dict(
        p.output_keys[1] => object,
        p.output_keys[2] => object.position
    )

to_abstract_value(p::Abstractor, ::GetPosition, objects::AbstractVector{Object}) =
    Dict(
        p.output_keys[1] => objects,
        p.output_keys[2] => [o.position for o in objects]
    )

from_abstract_value(p::Abstractor, ::GetPosition, object::Object, position::Tuple{Int64,Int64}) =
    Dict(
        p.output_keys[1] => Object(object.shape, position)
    )

from_abstract_value(p::Abstractor, ::GetPosition, objects::AbstractArray{Object}, positions::AbstractArray{Tuple{Int64,Int64}}) =
    Dict(
        p.output_keys[1] => [Object(o.shape, pos) for (o, pos) in zip(objects, positions)]
    )

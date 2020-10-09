

struct GetPosition <: AbstractorClass end

abs_keys(::GetPosition) = ["shapes", "positions"]

check_task_value(::GetPosition, value::Object, data, aux_values) = true
check_task_value(::GetPosition, value::AbstractVector{Object}, data, aux_values) = true


function wrap_func_call_shape_value(p::Abstractor, cls::CountObjects, func::Function, wrappers::AbstractVector{Function}, source_values...)
    if func == from_abstract_value
        wrap_func_call_value(p, cls, func, wrappers, source_values...)
    else
        invoke(wrap_func_call_shape_value, Tuple{Abstractor,AbstractorClass,Function,AbstractVector{Function},Vararg{Any}}, p, cls, func, wrappers, source_values...)
    end
end


to_abstract_value(p::Abstractor, ::GetPosition, object::Object) =
    Dict(
        p.output_keys[1] => ObjectShape(object),
        p.output_keys[2] => object.position
    )

to_abstract_value(p::Abstractor, ::GetPosition, objects::AbstractVector{Object}) =
    Dict(
        p.output_keys[1] => [ObjectShape(o) for o in objects],
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

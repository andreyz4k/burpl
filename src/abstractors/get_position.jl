

struct GetPosition <: AbstractorClass end

abs_keys(::GetPosition) = ["positions", "shapes"]

check_task_value(::GetPosition, value::Object, data, aux_values) = true
check_task_value(::GetPosition, value::AbstractVector{Object}, data, aux_values) = true


function wrap_func_call_shape_value(p::Abstractor{GetPosition}, func::Function, wrappers::AbstractVector{Function}, source_values...)
    if func == from_abstract_value
        wrap_func_call_value(p, func, wrappers, source_values...)
    else
        invoke(wrap_func_call_shape_value, Tuple{Abstractor,Function,AbstractVector{Function},Vararg{Any}}, p, func, wrappers, source_values...)
    end
end


to_abstract_value(p::Abstractor{GetPosition}, object::Object) =
    Dict(
        p.output_keys[2] => ObjectShape(object),
        p.output_keys[1] => object.position
    )

to_abstract_value(p::Abstractor{GetPosition}, objects::AbstractVector{Object}) =
    Dict(
        p.output_keys[2] => [ObjectShape(o) for o in objects],
        p.output_keys[1] => [o.position for o in objects]
    )

from_abstract_value(p::Abstractor{GetPosition}, position::Tuple{Int64,Int64}, object::Object) =
    Dict(
        p.output_keys[1] => Object(object.shape, position)
    )

from_abstract_value(p::Abstractor{GetPosition}, positions::AbstractArray{Tuple{Int64,Int64}}, objects::AbstractArray{Object}) =
    Dict(
        p.output_keys[1] => [Object(o.shape, pos) for (o, pos) in zip(objects, positions)]
    )

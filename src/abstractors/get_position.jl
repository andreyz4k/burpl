

struct GetPosition <: AbstractorClass end

abs_keys(::GetPosition) = ["position", "shape"]

check_task_value(::GetPosition, value::Object, data, aux_values) = true
check_task_value(::GetPosition, value::AbstractSet{Object}, data, aux_values) = !isempty(value)


function wrap_func_call_shape_value(
    p::Abstractor{GetPosition},
    func::Function,
    wrappers::AbstractVector{Function},
    source_values...,
)
    if func == from_abstract_value
        wrap_func_call_value(p, func, wrappers, source_values...)
    else
        invoke(
            wrap_func_call_shape_value,
            Tuple{Abstractor,Function,AbstractVector{Function},Vararg{Any}},
            p,
            func,
            wrappers,
            source_values...,
        )
    end
end


to_abstract_value(p::Abstractor{GetPosition}, object::Object) =
    Dict(p.output_keys[2] => ObjectShape(object), p.output_keys[1] => object.position)

to_abstract_value(p::Abstractor{GetPosition}, objects::AbstractSet{Object}) = Dict(
    p.output_keys[2] => ObjectsGroup(objects),
    p.output_keys[1] => reduce((a, b) -> min.(a, b), (obj.position for obj in objects)) .- 1,
)

from_abstract_value(p::Abstractor{GetPosition}, position::Tuple{Int64,Int64}, object::Object) =
    Dict(p.output_keys[1] => Object(object.shape, position))

function from_abstract_value(p::Abstractor{GetPosition}, position::Tuple{Int64,Int64}, objects::AbstractSet{Object})
    min_pos = reduce((a, b) -> min.(a, b), (obj.position for obj in objects)) .- 1
    Dict(p.output_keys[1] => Set([Object(o.shape, o.position .- min_pos .+ position) for o in objects]))
end

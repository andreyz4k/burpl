

struct GetColor <: AbstractorClass end

abs_keys(::GetColor) = ["color", "object_mask"]

check_task_value(::GetColor, value::Object, data, aux_values) = true

wrap_check_task_value(cls::GetColor, value::ObjectMask, data, aux_values) = false
wrap_check_task_value(cls::GetColor, value::ObjectShape, data, aux_values) = false

function wrap_func_call_mask_value(
    p::Abstractor{GetColor},
    func::Function,
    wrappers::AbstractVector{Function},
    source_values...,
)
    if func == from_abstract_value
        wrap_func_call_value(p, func, wrappers, source_values...)
    else
        invoke(
            wrap_func_call_mask_value,
            Tuple{Abstractor,Function,AbstractVector{Function},Vararg{Any}},
            p,
            func,
            wrappers,
            source_values...,
        )
    end
end


function to_abstract_value(p::Abstractor{GetColor}, object::Object)
    if p.from_output
        Dict(p.output_keys[2] => ObjectMask(object), p.output_keys[1] => get_color(object))
    else
        Dict(p.output_keys[2] => object, p.output_keys[1] => get_color(object))
    end
end


from_abstract_value(p::Abstractor{GetColor}, color::Color, object::Object) =
    Dict(p.output_keys[1] => Object(map(c -> c == -1 ? c : color.value, object.shape), object.position))

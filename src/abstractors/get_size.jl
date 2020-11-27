

struct GetSize <: ComputeFunctionClass end
abs_keys(::GetSize) = ["obj_size"]

check_task_value(::GetSize, value::Object, data, aux_values) = true
check_task_value(::GetSize, value::AbstractVector{Object}, data, aux_values) = true

to_abstract_value(p::Abstractor{GetSize}, source_value::Object) =
    Dict(p.output_keys[1] => size(source_value.shape))

to_abstract_value(p::Abstractor{GetSize}, source_value::AbstractVector{Object}) =
    Dict(p.output_keys[1] => [size(obj.shape) for obj in source_value])

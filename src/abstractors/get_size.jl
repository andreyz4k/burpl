

struct GetSize <: ComputeFunctionClass end
abs_keys(::GetSize) = ["obj_size"]

check_task_value(::GetSize, value::Object, data, aux_values) = true

to_abstract_value(p::Abstractor{GetSize}, source_value::Object) =
    Dict(p.output_keys[1] => (OInt(size(source_value.shape)[1]), OInt(size(source_value.shape)[2])))

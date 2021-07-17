
struct GetArea <: ComputeFunctionClass end
abs_keys(::GetArea) = ["obj_area"]

check_task_value(::GetArea, value::Object, data, aux_values) = true

to_abstract_value(p::Abstractor{GetArea}, source_value::Object) =
    Dict(p.output_keys[1] => sum(source_value.shape .!= -1))



struct CountObjects <: ComputeFunctionClass end

@memoize priority(cls::CountObjects) = 30
@memoize abs_keys(cls::CountObjects) = ["count"]

check_task_value(cls::CountObjects, value::AbstractVector, data, aux_values) = true

to_abstract_value(p::Abstractor, cls::CountObjects, source_value::AbstractVector, aux_values) =
    Dict(p.output_keys[1] => length(source_value))



struct DistanceBetweenObjects <: ComputeFunctionClass end

@memoize abs_keys(cls::DistanceBetweenObjects) = ["distance"]

check_task_value(cls::DistanceBetweenObjects, value::AbstractVector{Object}, data, aux_values) =
    length(value) == 2

to_abstract_value(p::Abstractor, cls::DistanceBetweenObjects, source_value, aux_values) =
    Dict(p.output_keys[1] => source_value[1].position .- source_value[2].position)

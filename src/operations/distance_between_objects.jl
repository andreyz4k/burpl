

struct DistanceBetweenObjects <: ComputeFunctionClass end

@memoize abs_keys(cls::DistanceBetweenObjects) = ["distance"]

check_task_value(cls::DistanceBetweenObjects, value::AbstractVector{Object}, data, aux_values) =
    length(value) == 2

function to_abstract_value(p::Abstractor, cls::DistanceBetweenObjects, source_value, aux_values)
    positions = sort([obj.position for obj in source_value])
    Dict(p.output_keys[1] => positions[2] .- positions[1])
end

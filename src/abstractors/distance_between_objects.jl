

struct DistanceBetweenObjects <: ComputeFunctionClass end

abs_keys(::DistanceBetweenObjects) = ["distance"]

check_task_value(::DistanceBetweenObjects, value::AbstractVector{Object}, data, aux_values) =
    length(value) == 2

function to_abstract_value(p::Abstractor{DistanceBetweenObjects}, source_value)
    positions = sort([obj.position for obj in source_value])
    Dict(p.output_keys[1] => positions[2] .- positions[1])
end

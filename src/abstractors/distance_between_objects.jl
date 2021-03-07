

struct DistanceBetweenObjects <: ComputeFunctionClass end

abs_keys(::DistanceBetweenObjects) = ["distance"]

check_task_value(::DistanceBetweenObjects, value::AbstractVector{Object}, data, aux_values) =
    length(value) == 2

wrap_func_call_vect_value(p::Abstractor{DistanceBetweenObjects}, func::Function, wrappers::AbstractVector{Function}, source_values...) =
    wrap_func_call_value(p, func, wrappers, source_values...)
    
function to_abstract_value(p::Abstractor{DistanceBetweenObjects}, source_value)
    positions = sort([obj.position for obj in source_value])
    Dict(p.output_keys[1] => positions[2] .- positions[1])
end

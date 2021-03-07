
using ..PatternMatching:common_value

struct CompactSimilarObjects <: AbstractorClass end

allow_concrete(::CompactSimilarObjects) = false
CompactSimilarObjects(key, to_abs) = Abstractor(CompactSimilarObjects(), key, to_abs)
abs_keys(::CompactSimilarObjects) = ["common_val", "count"]

init_create_check_data(::CompactSimilarObjects, key, solution) = Dict("effective" => false)

wrap_func_call_vect_value(p::Abstractor{CompactSimilarObjects}, func::Function, wrappers::AbstractVector{Function}, source_values...) =
    wrap_func_call_value(p, func, wrappers, source_values...)
    
function check_task_value(::CompactSimilarObjects, value::AbstractVector, data, aux_values)
    data["effective"] |= length(value) > 1
    (length(value) > 0) ? all(!isnothing(common_value(item, value[1])) for item in view(value, 2:length(value))) : true
end


to_abstract_value(p::Abstractor{CompactSimilarObjects}, objects::AbstractVector) =
     Dict(
        p.output_keys[1] => length(objects) > 0 ? objects[1] : nothing,
        p.output_keys[2] => length(objects)
    )

from_abstract_value(p::Abstractor{CompactSimilarObjects}, value, count) =
    Dict(
        p.output_keys[1] => fill(value, count)
    )

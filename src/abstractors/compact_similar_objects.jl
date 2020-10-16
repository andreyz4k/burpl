
struct CompactSimilarObjects <: AbstractorClass end

CompactSimilarObjects(key, to_abs) = Abstractor(CompactSimilarObjects(), key, to_abs)
abs_keys(::CompactSimilarObjects) = ["common_shape", "positions"]

init_create_check_data(::CompactSimilarObjects, key, solution) = Dict("effective" => false)

function check_task_value(::CompactSimilarObjects, value::AbstractVector{Object}, data, aux_values)
    data["effective"] |= length(value) > 1
    (length(value) > 0) ? all(obj.shape == value[1].shape for obj in view(value, 2:length(value))) : true
end


to_abstract_value(p::Abstractor{CompactSimilarObjects}, objects::AbstractVector{Object}) =
     Dict(
        p.output_keys[1] => length(objects) > 0 ? objects[1].shape : nothing,
        p.output_keys[2] => [obj.position for obj in objects]
    )

from_abstract_value(p::Abstractor{CompactSimilarObjects}, common_shape, positions) =
    Dict(
        p.output_keys[1] => [Object(common_shape, position) for position in positions]
    )

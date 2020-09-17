
struct CompactSimilarObjects <: AbstractorClass end

CompactSimilarObjects(key, to_abs) = Abstractor(CompactSimilarObjects(), key, to_abs)
@memoize abs_keys(p::CompactSimilarObjects) = ["common_shape", "positions"]

check_task_value(cls::CompactSimilarObjects, value, data, aux_values) = false
check_task_value(cls::CompactSimilarObjects, value::Array{Object,1}, data, aux_values) =
    (length(value) > 0) ? all(obj.shape == value[1].shape for obj in view(value, 2:length(value))) : true


to_abstract_value(p::Abstractor, cls::CompactSimilarObjects, source_value, aux_values) =
     Dict(
        p.output_keys[1] => length(source_value) > 0 ? source_value[1].shape : nothing,
        p.output_keys[2] => [obj.position for obj in source_value]
    )

from_abstract_value(p::Abstractor, cls::CompactSimilarObjects, source_values) =
    Dict(
        p.output_keys[1] => [Object(source_values[1], position) for position in source_values[2]]
    )

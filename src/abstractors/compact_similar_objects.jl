
using ..PatternMatching: common_value

struct CompactSimilarObjects <: AbstractorClass end

CompactSimilarObjects(key, to_abs) = Abstractor(CompactSimilarObjects(), key, to_abs, !to_abs)
abs_keys(::CompactSimilarObjects) = ["common_shape", "positions"]

init_create_check_data(::CompactSimilarObjects, key, solution) = Dict("effective" => false)

wrap_check_task_value(cls::CompactSimilarObjects, value::ObjectsGroup, data, aux_values) = false

function check_task_value(::CompactSimilarObjects, value::AbstractSet{Object}, data, aux_values)
    data["effective"] |= length(value) > 1
    if isempty(value)
        return true
    end
    f = first(value)
    all(f.shape == item.shape for item in value)
end


to_abstract_value(p::Abstractor{CompactSimilarObjects}, objects::AbstractSet{Object}) = Dict(
    p.output_keys[1] => length(objects) > 0 ? ObjectShape(first(objects)) : nothing,
    p.output_keys[2] => Set([o.position for o in objects]),
)

from_abstract_value(p::Abstractor{CompactSimilarObjects}, shape_template, positions) =
    Dict(p.output_keys[1] => Set([Object(shape_template.shape, pos) for pos in positions]))



struct SplitObject <: AbstractorClass end
# @memoize allow_concrete(p::SplitObject) = false
SplitObject(key, to_abs) = Abstractor(SplitObject(), key, to_abs)
@memoize abs_keys(cls::SplitObject) = ["splitted"]

init_create_check_data(cls::SplitObject, key, solution) = Dict("effective" => false)

function check_task_value(cls::SplitObject, value::Object, data, aux_values)
    data["effective"] |= sum(value.shape .!= -1) > 1
    true
end

function to_abstract_value(p::Abstractor, cls::SplitObject, object::Object, aux_values)
    res = Object[]
    for i in 1:size(object.shape)[1], j in 1:size(object.shape)[2]
        if object.shape[i, j] != -1
            push!(res, Object([object.shape[i, j]], object.position .+ (i - 1, j - 1)))
        end
    end
    return Dict(p.output_keys[1] => res)
end

function _merge_objects(obj1::Object, obj2::Object)
    new_pos = min.(obj1.position, obj2.position)
    max_border = max.(obj1.position .+ size(obj1.shape), obj2.position .+ size(obj2.shape))
    new_size = max_border .- new_pos
    new_shape = fill(-1, new_size)
    draw_object!(new_shape, Object(obj1.shape, obj1.position .- new_pos .+ (1, 1)))
    draw_object!(new_shape, Object(obj2.shape, obj2.position .- new_pos .+ (1, 1)))
    return Object(new_shape, new_pos)
end

function from_abstract_value(p::Abstractor, cls::SplitObject, source_values)
    result = source_values[1][1]
    for obj in source_values[1][2:end]
        result = _merge_objects(result, obj)
    end
    return Dict(p.output_keys[1] => result)
end

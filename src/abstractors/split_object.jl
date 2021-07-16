

struct SplitObject <: AbstractorClass end
allow_concrete(::SplitObject) = false
SplitObject(key, to_abs) = Abstractor(SplitObject(), key, to_abs, !to_abs)
abs_keys(::SplitObject) = ["splitted"]

init_create_check_data(::SplitObject, key, solution) = Dict("effective" => false)

function check_task_value(::SplitObject, value::Object, data, aux_values)
    data["effective"] |= sum(value.shape .!= -1) > 1
    true
end

function to_abstract_value(p::Abstractor{SplitObject}, object::Object)
    res = Set{Object}()
    for i = 1:size(object.shape)[1], j = 1:size(object.shape)[2]
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

function from_abstract_value(p::Abstractor{SplitObject}, objects)
    result = first(objects)
    for obj in objects
        result = _merge_objects(result, obj)
    end
    return Dict(p.output_keys[1] => result)
end

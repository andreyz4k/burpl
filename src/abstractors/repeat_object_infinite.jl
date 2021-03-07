
struct RepeatObjectInfinite <: AbstractorClass end

RepeatObjectInfinite(key, to_abs, taskdata) = Abstractor(RepeatObjectInfinite(), key, to_abs, aux_keys(RepeatObjectInfinite(), key, taskdata))
abs_keys(::RepeatObjectInfinite) = ["first", "step"]
aux_keys(::RepeatObjectInfinite) = ["grid_size"]

init_create_check_data(::RepeatObjectInfinite, key, solution) = Dict("effective" => false)

using ..ObjectPrior:point_in_rect

function check_task_value(::RepeatObjectInfinite, value::AbstractVector{Object}, data, aux_values)
    if isempty(value)
        return false
    end
    items = sort(value, by=obj -> obj.position)
    if any(obj.shape != items[1].shape for obj in view(items, 2:length(items)))
        return false
    end
    if any(items[i].position .- items[i - 1].position != items[i + 1].position .- items[i].position for i in 2:(length(items) - 1))
        return false
    end
    if length(items) > 1
        data["effective"] = true
        step = items[2].position .- items[1].position
        grid_size = aux_values[1]
        last_pos = items[1].position .+ step .* length(items)
        prev_pos = items[1].position .- step
        if point_in_rect(prev_pos, (1, 1), grid_size) && point_in_rect(last_pos, (1, 1), grid_size)
            return false
        end
    end
    true
end


needed_input_keys(p::Abstractor{RepeatObjectInfinite}) =
    p.to_abstract ? p.input_keys : p.input_keys[1:2:3]

wrap_func_call_vect_value(p::Abstractor{RepeatObjectInfinite}, func::Function, wrappers::AbstractVector{Function}, source_values...) =
    wrap_func_call_value(p, func, wrappers, source_values...)

function to_abstract_value(p::Abstractor{RepeatObjectInfinite}, source_value, grid_size)
    objects = sort(source_value, by=obj -> obj.position)
    if length(objects) == 1
        return Dict(p.output_keys[1] => objects[1])
    end
    if length(objects) > 1
        step = objects[2].position .- objects[1].position
        last_pos = objects[1].position .+ step .* length(objects)
        options = Set()
        if !point_in_rect(last_pos, (1, 1), grid_size)
            push!(options, (objects[1], step))
        end
        prev_pos = objects[1].position .- step
        if !point_in_rect(prev_pos, (1, 1), grid_size)
            push!(options, (objects[end], step .* (-1)))
        end

        if length(options) > 0
            return make_either(p.output_keys, options)
        end
    end
end

function from_abstract_value(p::Abstractor{RepeatObjectInfinite}, first, step, grid_size)
    out_value = [first]
    i = 1
    while !isnothing(step)
        pos = first.position .+ step .* i
        if any((pos .+ size(first.shape) .- (1, 1)) .< (1, 1)) || any(pos .> grid_size)
            break
        end
        push!(out_value, Object(first.shape, pos))
        i += 1
    end
    return Dict(p.output_keys[1] => out_value)
end

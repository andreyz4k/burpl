
struct SolidObjects <: AbstractorClass end

SolidObjects(key, to_abs) = Abstractor(SolidObjects(), key, to_abs)
abs_keys(::SolidObjects) = ["spatial_objects", "grid_size"]
priority(::SolidObjects) = 6

using ..ObjectPrior:find_objects,draw_object!,get_color

init_create_check_data(::SolidObjects, key, solution) = Dict("effective" => false)

function check_task_value(::SolidObjects, value::AbstractArray{Int,2}, data, aux_values)
    data["effective"] |= length(unique(value)) > 1
    true
end


needed_input_keys(p::Abstractor{SolidObjects}) =
    p.to_abstract ? p.input_keys : p.input_keys[1:1]


to_abstract_value(p::Abstractor{SolidObjects}, source_value::AbstractArray{Int,2}) =
    Dict(
        p.output_keys[1] => find_objects(source_value),
        p.output_keys[2] => size(source_value)
    )

function from_abstract_value(p::Abstractor{SolidObjects}, objects, grid_size)
    if isnothing(grid_size)
    grid_size = reduce((a, b) -> max.(a, b), (obj.position .+ size(obj.shape) .- (1, 1) for obj in objects), init=(0, 0))
    end
    
    grid = fill(-1, grid_size...)
    for obj in objects
        draw_object!(grid, obj)
    end
    return Dict(p.output_keys[1] => grid)
end

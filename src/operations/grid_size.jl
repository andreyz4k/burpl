
struct GridSize <: AbstractorClass end

GridSize(key, to_abs) = Abstractor(GridSize(), key, to_abs)
@memoize abs_keys(cls::GridSize) = ["grid", "grid_size"]
@memoize priority(cls::GridSize) = 1

init_create_check_data(cls::GridSize, key, solution) = Dict("effective" => false)

function check_task_value(cls::GridSize, value::AbstractArray{Int,2}, data, aux_values)
    if !data["effective"]
        data["effective"] = !any(val == size(value) for val in aux_values)
    end
    true
end

create_abstractors(cls::GridSize, data, key) =
    data["effective"] ? invoke(create_abstractors, Tuple{AbstractorClass,Any,Any}, cls, data, key) : []

get_aux_values_for_task(cls::AbstractorClass, task_data, key, solution) =
    values(task_data)

needed_input_keys(p::Abstractor, cls::GridSize) =
    p.to_abstract ? p.input_keys : p.input_keys[2:2]

to_abstract_value(p::Abstractor, cls::GridSize, source_value::AbstractArray{Int,2}, aux_values) =
    Dict(p.output_keys[1] => source_value, p.output_keys[2] => size(source_value))

function from_abstract_value(p::Abstractor, cls::GridSize, source_values)
    grid, grid_size = source_values
    new_grid = fill(0, grid_size)
    if !isnothing(grid)
        intersection = 1:min(grid_size[1], size(grid)[1]), 1:min(grid_size[2], size(grid)[2])
        new_grid[intersection...] = grid[intersection...]
    end
    return Dict(p.output_keys[1] => new_grid)
end

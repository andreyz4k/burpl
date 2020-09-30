
struct GridSize <: AbstractorClass end

GridSize(key, to_abs) = Abstractor(GridSize(), key, to_abs)
@memoize abs_keys(cls::GridSize) = ["grid", "grid_size"]
@memoize priority(cls::GridSize) = 6

init_create_check_data(cls::GridSize, key, solution) = Dict("effective" => false)

function check_task_value(cls::GridSize, value::AbstractArray{Int,2}, data, aux_values)
    data["effective"] |= !any(val == size(value) for val in aux_values)
    true
end

get_aux_values_for_task(cls::GridSize, task_data, key, solution) =
    in(key, solution.unfilled_fields) ?
    values(filter(kv -> isa(kv[2], Tuple{Int,Int}) &&
                        (in(kv[1], solution.unfilled_fields) ||
                         in(kv[1], solution.transformed_fields) ||
                         in(kv[1], solution.filled_fields)),
                  task_data)) :
    values(filter(kv -> isa(kv[2], Tuple{Int,Int}) &&
                        !in(kv[1], solution.unfilled_fields) &&
                        !in(kv[1], solution.transformed_fields) &&
                        !in(kv[1], solution.filled_fields),
                  task_data))

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
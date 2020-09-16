
struct GridSize <: GridPerceptorClass end

GridSize(source) = GridPerceptor(GridSize(), source)
@memoize abs_keys(p::GridSize) = ["grid_size"]
@memoize priority(p::GridSize) = 1

function to_abstract(p::GridPerceptor, cls::GridSize, grid::Array{Int,2}, previous_data::Dict)::Dict
    data = invoke(to_abstract, Tuple{GridPerceptor,GridPerceptorClass,Array{Int,2},Dict}, p, cls, grid, previous_data)
    data[p.output_keys[1]] = size(grid)
    data
end

function from_abstract(p::GridPerceptor, cls::GridSize, data::Dict, existing_grid::Array{Int,2})::Array{Int,2}
    size = data[p.input_keys[1]]
    grid = zeros(size)
    grid
end

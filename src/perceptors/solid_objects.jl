
struct SolidObjects <: GridPerceptorClass end

SolidObjects(source) = GridPerceptor(SolidObjects(), source)
@memoize abs_keys(p::SolidObjects) = ["spatial_objects"]

using ..ObjectPrior:find_objects,draw_object!,get_color

function to_abstract(p::GridPerceptor, cls::SolidObjects, grid::Array{Int,2}, previous_data::Dict)::Dict
    data = invoke(to_abstract, Tuple{GridPerceptor,GridPerceptorClass,Array{Int,2},Dict}, p, cls, grid, previous_data)
    objects = find_objects(grid)
    data[p.output_keys[1]] = objects
    data
end

function from_abstract(p::GridPerceptor, cls::SolidObjects, data::Dict, existing_grid::Array{Int,2})::Array{Int,2}
    grid = invoke(from_abstract, Tuple{GridPerceptor,GridPerceptorClass,Dict,Array{Int,2}}, p, cls, data, existing_grid)
    for obj in data[p.input_keys[1]]
        draw_object!(grid, obj)
    end
    grid
end

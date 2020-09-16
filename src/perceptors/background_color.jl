
struct BackgroundColor <: GridPerceptorClass end

BackgroundColor(source) = GridPerceptor(BackgroundColor(), source)
@memoize abs_keys(p::BackgroundColor) = ["background"]
@memoize detail_keys(p::BackgroundColor) = ["spatial_objects"]

function to_abstract(p::GridPerceptor, cls::BackgroundColor, grid::Array{Int,2}, previous_data::Dict)::Dict
    out_data = invoke(to_abstract, Tuple{GridPerceptor,GridPerceptorClass,Array{Int,2},Dict}, p, cls, grid, previous_data)
    background = nothing
    grid_size = *(size(grid)...)
    for object_item in out_data[p.input_keys[1]]
        obj_size = *(size(object_item.shape)...)
        if obj_size == grid_size
            background = object_item
            break
        elseif obj_size * 2 > grid_size &&
                (isnothing(background) || *(size(background.shape)...) <
                    *(size(object_item.shape)...))
            background = object_item
        end
    end
    if !isnothing(background)
        out_data[p.output_keys[1]] = get_color(background)
    end
    return out_data
end

function from_abstract(p::GridPerceptor, cls::BackgroundColor, data::Dict, existing_grid::Array{Int,2})::Array{Int,2}
    grid = fill(data[p.input_keys[1]], size(existing_grid))
end


struct SplittedBackground <: GridPerceptorClass end

SplittedBackground(source) = GridPerceptor(SplittedBackground(), source)
@memoize abs_keys(p::SplittedBackground) = ["background"]
@memoize detail_keys(p::SplittedBackground) = ["spatial_objects"]

function to_abstract(p::GridPerceptor, cls::SplittedBackground, grid::Array{Int,2}, previous_data::Dict)::Dict
    out_data = to_abstract(p, BackgroundColor(), grid, previous_data)
    if !haskey(out_data, p.output_keys[1])
        color_sizes = Dict()
        for object_item in out_data[p.input_keys[1]]
            obj_size = *(size(object_item.shape)...)
            color = get_color(object_item)
            color_sizes[color] = obj_size + get!(color_sizes, color, 0)
        end
        _, color = findmax(color_sizes)
        out_data[p.output_keys[1]] = color
    end
    return out_data
end

from_abstract(p::GridPerceptor, cls::SplittedBackground, data::Dict, existing_grid::Array{Int,2})::Array{Int,2} =
    from_abstract(p, BackgroundColor(), data, existing_grid)

get_sorting_keys(p::GridPerceptor, cls::Union{BackgroundColor,SplittedBackground}) = p.to_abstract ? p.output_keys : detail_keys(cls, "output")

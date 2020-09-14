export Perceptors
module Perceptors

using Memoization


abstract type GridPerceptorClass end

@memoize detail_keys(p::GridPerceptorClass) = []
@memoize abs_keys(p::GridPerceptorClass) = []
@memoize priority(p::GridPerceptorClass) = 2

@memoize pr_abs_keys(cls::GridPerceptorClass, source::String) = [source * "|" * key for key in abs_keys(cls)]
@memoize pr_detail_keys(cls::GridPerceptorClass, source::String) = [source * "|" * key for key in detail_keys(cls)]

import ..Operations.Operation


struct GridPerceptor <: Operation
    cls::GridPerceptorClass
    to_abstract::Bool
    input_keys::Array{String}
    output_keys::Array{String}
end

function GridPerceptor(cls, source)
    if source == "output"
        return GridPerceptor(cls, false, pr_abs_keys(cls, source), [])
    else
        return GridPerceptor(cls, true, pr_detail_keys(cls, source), pr_abs_keys(cls, source))
    end
end

function (p::GridPerceptor)(input_grid, output_grid, task_data)
    if p.to_abstract
        return output_grid, to_abstract(p, p.cls, input_grid, task_data)
    else
        return from_abstract(p, p.cls, task_data, output_grid), task_data
    end
end

to_abstract(p::GridPerceptor, ::GridPerceptorClass, grid::Array{Int,2}, previous_data::Dict)::Dict =
    copy(previous_data)

from_abstract(p::GridPerceptor, ::GridPerceptorClass, data::Dict, existing_grid::Array{Int,2})::Array{Int,2} =
    copy(existing_grid)

Base.show(io::IO, p::GridPerceptor) = print(io, string(nameof(typeof(p.cls))),
                                            p.to_abstract ? "(\"input\")" : "(\"output\")")

Base.:(==)(a::GridPerceptor, b::GridPerceptor) = a.cls == b.cls && a.to_abstract == b.to_abstract

try_apply(perceptor, grids, observed_data) =
    any(to_abstract(perceptor, perceptor.cls, grid, data) != data for (grid, data) in zip(grids, observed_data))

function create(cls, solution, source, grids)::Array{Tuple{Float64,NamedTuple{(:to_abstract, :from_abstract),Tuple{GridPerceptor,GridPerceptor}}},1}
    if !all(haskey(solution.observed_data[1], key) for key in pr_detail_keys(cls, source)) ||
            all(haskey(solution.observed_data[1], key) for key in pr_abs_keys(cls, source))
        return []
    end
    to_abs_perceptor = GridPerceptor(cls, true, pr_detail_keys(cls, source), pr_abs_keys(cls, source))
    if try_apply(to_abs_perceptor, grids, solution.observed_data)
        return [(priority(cls), (to_abstract = to_abs_perceptor,
            from_abstract = GridPerceptor(cls, false, pr_abs_keys(cls, source), [])))]
    else
        return []
    end
end


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


struct SolidObjects <: GridPerceptorClass end

SolidObjects(source) = GridPerceptor(SolidObjects(), source)
@memoize abs_keys(p::SolidObjects) = ["spatial_objects"]

using ..ObjectPrior:find_objects,draw_object!

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
        out_data[p.output_keys[1]] = maximum(background.shape)
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
            color = maximum(object_item.shape)
            color_sizes[color] = obj_size + get!(color_sizes, color, 0)
        end
        _, color = findmax(color_sizes)
        out_data[p.output_keys[1]] = color
    end
    return out_data
end

classes = [GridSize(), SolidObjects(), BackgroundColor(), SplittedBackground()]
end

module Perceptors

abstract type GridPerceptorClass end

detail_keys(p::GridPerceptorClass) = []
abs_keys(p::GridPerceptorClass) = []
priority(p::GridPerceptorClass) = 2

struct GridPerceptor
    cls::GridPerceptorClass
    source::String
    abs_keys::Array{String}
    detail_keys::Array{String}
    GridPerceptor(source, cls) = new(cls, source,
                                [source * "|" * key for key in abs_keys(cls)],
                                [source * "|" * key for key in detail_keys(cls)])
end

to_abstract(p::GridPerceptor, ::Val{GridPerceptorClass}, grid::Array{Int,2}, previous_data::Dict)::Dict =
    copy(previous_data)

from_abstract(p::GridPerceptor, ::Val{GridPerceptorClass}, data::Dict, existing_grid::Array{Int,2})::Array{Int,2} =
    copy(existing_grid)

struct GridSize <: GridPerceptorClass end

abs_keys(p::GridSize) = ["grid_size"]
priority(p::GridSize) = 2

function to_abstract(p::GridPerceptor, cls::Val{GridSize}, grid::Array{Int,2}, previous_data::Dict)::Dict
    data = invoke(to_abstract, Tuple{GridPerceptor,Val{GridPerceptorClass},Array{Int,2},Dict}, p, cls, grid, previous_data)
    data[p.detail_keys[1]] = size(grid)
    data
end

function from_abstract(p::GridPerceptor, cls::Val{GridSize}, data::Dict, existing_grid::Array{Int,2})::Array{Int,2}
    size = data[p.abs_keys[1]]
    grid = zeros(size)
end

include("operation.jl")

function wrap_to_abstract(p::GridPerceptor)
    function inner(input_grid, output_grid, task_data)
        return output_grid, to_abstract(p, Val(p.cls), input_grid, task_data)
    end
    Operations.Operation(
        inner, p.detail_keys, p.abs_keys, string(nameof(typeof(p.cls))) * "('input')"
    )
end

function wrap_from_abstract(p::GridPerceptor)
    function inner(_, output_grid, task_data)
        return from_abstract(p, Val(p.cls), task_data, output_grid), task_data
    end
    Operations.Operation(
        inner, p.abs_keys, [], string(nameof(typeof(p.cls))) * "('output')"
    )
end


function create(cls, solution, source, grids)
    println("create")
    perceptor = GridPerceptor(source, cls)
    if !all(haskey(solution.observed_data[1], key) for key in perceptor.detail_keys) ||
            all(haskey(solution.observed_data[1], key) for key in perceptor.abs_keys)
        return []
    end
    return [(priority(cls), (to_abstract = wrap_to_abstract(perceptor),
        from_abstract = wrap_from_abstract(perceptor)))]
end


classes = [GridSize()]
end
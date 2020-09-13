module Perceptors

abstract type GridPerceptorClass end

detail_keys(p::GridPerceptorClass) = []
abs_keys(p::GridPerceptorClass) = []
priority(p::GridPerceptorClass) = 2

import ..Operations.Operation

struct GridPerceptor <: Operation
    cls::GridPerceptorClass
    to_abstract::Bool
    input_keys::Array{String}
    output_keys::Array{String}
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
                                            p.to_abstract ? "('input')" : "('output')")

Base.:(==)(a::GridPerceptor, b::GridPerceptor) = a.cls == b.cls && a.to_abstract == b.to_abstract

struct GridSize <: GridPerceptorClass end

abs_keys(p::GridSize) = ["grid_size"]
priority(p::GridSize) = 2

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

try_apply(perceptor, grids, observed_data) =
    any(to_abstract(perceptor, perceptor.cls, grid, data) != data for (grid, data) in zip(grids, observed_data))

function create(cls, solution, source, grids)::Array{Tuple{Float64,NamedTuple{(:to_abstract, :from_abstract),Tuple{GridPerceptor,GridPerceptor}}},1}
    pr_abs_keys = [source * "|" * key for key in abs_keys(cls)]
    pr_detail_keys = [source * "|" * key for key in detail_keys(cls)]
    if !all(haskey(solution.observed_data[1], key) for key in pr_detail_keys) ||
            all(haskey(solution.observed_data[1], key) for key in pr_abs_keys)
        return []
    end
    to_abs_perceptor = GridPerceptor(cls, true, pr_detail_keys, pr_abs_keys)
    if try_apply(to_abs_perceptor, grids, solution.observed_data)
        return [(priority(cls), (to_abstract = to_abs_perceptor,
            from_abstract = GridPerceptor(cls, false, pr_abs_keys, [])))]
    else
        return []
    end
end


classes = [GridSize()]
end

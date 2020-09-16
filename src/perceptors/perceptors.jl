export Perceptors
module Perceptors

using Memoization


abstract type GridPerceptorClass end

@memoize detail_keys(p::GridPerceptorClass) = []
@memoize abs_keys(p::GridPerceptorClass) = []
@memoize priority(p::GridPerceptorClass) = 2

@memoize abs_keys(cls::GridPerceptorClass, source::String) = [source * "|" * key for key in abs_keys(cls)]
@memoize detail_keys(cls::GridPerceptorClass, source::String) = [source * "|" * key for key in detail_keys(cls)]

import ..Operations


struct GridPerceptor <: Operations.Operation
    cls::GridPerceptorClass
    to_abstract::Bool
    input_keys::Array{String}
    output_keys::Array{String}
end

function GridPerceptor(cls::GridPerceptorClass, source::String)
    if source == "output"
        return GridPerceptor(cls, false, abs_keys(cls, source), [])
    else
        return GridPerceptor(cls, true, detail_keys(cls, source), abs_keys(cls, source))
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
    if !all(haskey(solution.observed_data[1], key) for key in detail_keys(cls, source)) ||
            all(haskey(solution.observed_data[1], key) for key in abs_keys(cls, source))
        return []
    end
    to_abs_perceptor = GridPerceptor(cls, true, detail_keys(cls, source), abs_keys(cls, source))
    if try_apply(to_abs_perceptor, grids, solution.observed_data)
        return [(priority(cls), (to_abstract = to_abs_perceptor,
            from_abstract = GridPerceptor(cls, false, abs_keys(cls, source), [])))]
    else
        return []
    end
end

Operations.get_sorting_keys(p::GridPerceptor) = get_sorting_keys(p, p.cls)
get_sorting_keys(p::GridPerceptor, cls::GridPerceptorClass) = p.output_keys

include("grid_size.jl")
include("solid_objects.jl")
include("background_color.jl")


using InteractiveUtils:subtypes
classes = [cls() for cls in subtypes(GridPerceptorClass)]
end

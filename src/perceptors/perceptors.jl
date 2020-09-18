export Perceptors
module Perceptors

using Memoization


abstract type GridPerceptorClass end

import ..Operations


from_abstract(p::GridPerceptor, ::GridPerceptorClass, data::Dict, existing_grid::Array{Int,2})::Array{Int,2} =
    copy(existing_grid)

Operations.get_sorting_keys(p::GridPerceptor) = get_sorting_keys(p, p.cls)
get_sorting_keys(p::GridPerceptor, cls::GridPerceptorClass) = p.output_keys

include("grid_size.jl")
include("solid_objects.jl")
include("background_color.jl")


using InteractiveUtils:subtypes
classes = [cls() for cls in subtypes(GridPerceptorClass)]
end

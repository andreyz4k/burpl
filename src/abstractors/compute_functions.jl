

abstract type ComputeFunctionClass <: AbstractorClass end

priority(::ComputeFunctionClass) = 10

ComputeFunction(cls::ComputeFunctionClass, key::String, found_aux_keys::AbstractVector{String}=String[]) =
    Abstractor(cls, key, true, found_aux_keys)

function create(cls::ComputeFunctionClass, solution, key)::Array{Tuple{Float64,NamedTuple{(:to_abstract, :from_abstract),Tuple{Abstractor,Abstractor}}},1}
    if in(key, solution.unfilled_fields)
        return []
    end
    invoke(create, Tuple{AbstractorClass,Any,Any}, cls, solution, key)
end


create_abstractors(cls::ComputeFunctionClass, data, key, found_aux_keys) =
    [(priority(cls), (to_abstract = ComputeFunction(cls, key, found_aux_keys),
                      from_abstract = Abstractor(Noop(), key, false, String[])))]

include("aligned_with_border.jl")
include("distance_between_objects.jl")
include("group_max.jl")
include("group_min.jl")
include("get_size.jl")
include("max_value.jl")
include("min_value.jl")

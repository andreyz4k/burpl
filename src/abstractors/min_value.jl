

struct MinValue <: ComputeFunctionClass end

abs_keys(::MinValue) = ["min_value"]
priority(::MinValue) = 15

check_task_value(::MinValue, value::AbstractVector{T}, data, aux_values) where {T<:Union{OInt,Tuple{OInt,OInt}}} =
    length(value) > 0

to_abstract_value(p::Abstractor{MinValue}, source_value::AbstractVector) =
    Dict(p.output_keys[1] => reduce((a, b) -> min.(a, b), source_value))

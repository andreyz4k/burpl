

struct MaxValue <: ComputeFunctionClass end

abs_keys(::MaxValue) = ["max_value"]
priority(::MaxValue) = 15

check_task_value(::MaxValue, value::AbstractVector{T}, data, aux_values) where
    T <: Union{Int64,Tuple{Int64,Int64}} = length(value) > 0

wrap_func_call_vect_value(p::Abstractor{MaxValue}, func::Function, wrappers::AbstractVector{Function}, source_values...) =
    wrap_func_call_value(p, func, wrappers, source_values...)
    
to_abstract_value(p::Abstractor{MaxValue}, source_value::AbstractVector) =
    Dict(p.output_keys[1] => reduce((a, b) -> max.(a, b), source_value))

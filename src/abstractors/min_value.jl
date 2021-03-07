

struct MinValue <: ComputeFunctionClass end

abs_keys(::MinValue) = ["min_value"]
priority(::MinValue) = 15

check_task_value(::MinValue, value::AbstractVector{T}, data, aux_values) where
    T <: Union{Int64,Tuple{Int64,Int64}} = length(value) > 0

wrap_func_call_vect_value(p::Abstractor{MinValue}, func::Function, wrappers::AbstractVector{Function}, source_values...) =
    wrap_func_call_value(p, func, wrappers, source_values...)
    
to_abstract_value(p::Abstractor{MinValue}, source_value::AbstractVector) =
    Dict(p.output_keys[1] => reduce((a, b) -> min.(a, b), source_value))

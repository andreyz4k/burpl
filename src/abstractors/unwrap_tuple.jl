

struct UnwrapTuple <: AbstractorClass end
UnwrapTuple(key, to_abs) = Abstractor(UnwrapTuple(), key, to_abs)
abs_keys(::UnwrapTuple) = ["unwrapped"]

check_task_value(::UnwrapTuple, value::Tuple{Any}, data, aux_values) = true
check_task_value(cls::UnwrapTuple, value::AbstractVector, data, aux_values) =
    all(check_task_value(cls, v, data, aux_values) for v in value)

to_abstract_value(p::Abstractor{UnwrapTuple}, source_value::Tuple) = Dict(p.output_keys[1] => source_value[1])

to_abstract_value(p::Abstractor{UnwrapTuple}, source_value::AbstractVector) =
    Dict(p.output_keys[1] => [v[1] for v in source_value])

from_abstract_value(p::Abstractor{UnwrapTuple}, source_value) = Dict(p.output_keys[1] => (source_value,))

from_abstract_value(p::Abstractor{UnwrapTuple}, source_value::AbstractVector) =
    Dict(p.output_keys[1] => [(v,) for v in source_value])

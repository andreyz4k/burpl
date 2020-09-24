

struct UnwrapTuple <: AbstractorClass end
UnwrapTuple(key, to_abs) = Abstractor(UnwrapTuple(), key, to_abs)
@memoize abs_keys(cls::UnwrapTuple) = ["unwrapped"]

check_task_value(cls::UnwrapTuple, value::Tuple{Any}, data, aux_values) = true
check_task_value(cls::UnwrapTuple, value::AbstractVector, data, aux_values) =
    all(check_task_value(cls, v, data, aux_values) for v in value)

to_abstract_value(p::Abstractor, cls::UnwrapTuple, source_value::Tuple, aux_values) =
    Dict(p.output_keys[1] => source_value[1])

to_abstract_value(p::Abstractor, cls::UnwrapTuple, source_value::AbstractVector, aux_values) =
    Dict(p.output_keys[1] => [v[1] for v in source_value])

_wrap_in_tuple(value) = (value,)
_wrap_in_tuple(value::AbstractVector) =
    [_wrap_in_tuple(v) for v in value]

from_abstract_value(p::Abstractor, cls::UnwrapTuple, source_values) =
    Dict(p.output_keys[1] => _wrap_in_tuple(source_values[1]))

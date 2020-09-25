

struct RemoveRedundantDict <: AbstractorClass end

RemoveRedundantDict(key, to_abs) = Abstractor(RemoveRedundantDict(), key, to_abs)
@memoize abs_keys(cls::RemoveRedundantDict) = ["to_value"]

wrap_check_task_value(cls::RemoveRedundantDict, value::AbstractDict, data, aux_values) =
    check_task_value(cls, value, data, aux_values)

check_task_value(cls::RemoveRedundantDict, value::AbstractDict, data, aux_values) =
    length(Set(values(value))) == 1

wrap_to_abstract_value(p::Abstractor, cls::RemoveRedundantDict, source_value::AbstractDict, aux_values) =
    to_abstract_value(p, cls, source_value, aux_values)

to_abstract_value(p::Abstractor, cls::RemoveRedundantDict, source_value::AbstractDict, aux_values) =
    Dict(p.output_keys[1] => first(values(source_value)))

from_abstract_value(p::Abstractor, cls::RemoveRedundantDict, source_values) =
    Dict(p.output_keys[1] => source_values[1])

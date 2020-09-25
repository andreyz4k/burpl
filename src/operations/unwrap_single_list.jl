

struct UnwrapSingleList <: AbstractorClass end

UnwrapSingleList(key, to_abs) = Abstractor(UnwrapSingleList(), key, to_abs)
@memoize abs_keys(cls::UnwrapSingleList) = ["single_value"]

check_task_value(cls::UnwrapSingleList, value::AbstractVector, data, aux_values) =
    length(value) == 1

to_abstract_value(p::Abstractor, cls::UnwrapSingleList, source_value, aux_values) =
    Dict(p.output_keys[1] => source_value[1])

from_abstract_value(p::Abstractor, cls::UnwrapSingleList, source_values) =
    Dict(p.output_keys[1] => source_values)

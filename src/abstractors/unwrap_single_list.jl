

struct UnwrapSingleList <: AbstractorClass end

UnwrapSingleList(key, to_abs) = Abstractor(UnwrapSingleList(), key, to_abs)
abs_keys(::UnwrapSingleList) = ["single_value"]

check_task_value(::UnwrapSingleList, value::AbstractVector, data, aux_values) =
    length(value) == 1

to_abstract_value(p::Abstractor, ::UnwrapSingleList, source_value) =
    Dict(p.output_keys[1] => source_value[1])

from_abstract_value(p::Abstractor, ::UnwrapSingleList, source_value) =
    Dict(p.output_keys[1] => [source_value])

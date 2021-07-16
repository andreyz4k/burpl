

struct UnwrapSingleList <: AbstractorClass end

UnwrapSingleList(key, to_abs) = Abstractor(UnwrapSingleList(), key, to_abs, !to_abs)
abs_keys(::UnwrapSingleList) = ["single_value"]

check_task_value(::UnwrapSingleList, value::AbstractSet, data, aux_values) = length(value) == 1

to_abstract_value(p::Abstractor{UnwrapSingleList}, source_value) = Dict(p.output_keys[1] => first(source_value))

from_abstract_value(p::Abstractor{UnwrapSingleList}, source_value) = Dict(p.output_keys[1] => Set([source_value]))

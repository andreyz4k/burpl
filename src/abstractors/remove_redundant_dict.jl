

struct RemoveRedundantDict <: AbstractorClass end

RemoveRedundantDict(key, to_abs) = Abstractor(RemoveRedundantDict(), key, to_abs)
@memoize abs_keys(::RemoveRedundantDict) = ["to_value", "group_keys"]

wrap_check_task_value(cls::RemoveRedundantDict, value::AbstractDict, data, aux_values) =
    check_task_value(cls, value, data, aux_values)

check_task_value(::RemoveRedundantDict, value::AbstractDict, data, aux_values) =
    length(Set(values(value))) == 1


function wrap_func_call_dict_value(p::Abstractor, cls::RemoveRedundantDict, func::Function, wrappers::AbstractVector{Function}, source_values...)
    if func != from_abstract_value
        wrap_func_call_value(p, cls, func, wrappers, source_values...)
    else
        invoke(wrap_func_call_dict_value, Tuple{Abstractor,AbstractorClass,Function,AbstractVector{Function},Vararg{Any}}, p, cls, func, wrappers, source_values...)
    end
end

to_abstract_value(p::Abstractor, ::RemoveRedundantDict, source_value::AbstractDict) =
    Dict(
        p.output_keys[1] => first(values(source_value)),
        p.output_keys[2] => sort(collect(keys(source_value)))
        )

from_abstract_value(p::Abstractor, ::RemoveRedundantDict, value, keys) =
    Dict(p.output_keys[1] => Dict(key => value for key in keys))

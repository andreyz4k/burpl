

struct CountObjects <: AbstractorClass end

CountObjects(key, to_abs) = Abstractor(CountObjects(), key, to_abs)
priority(::CountObjects) = 30
abs_keys(::CountObjects) = ["counted", "length"]

check_task_value(::CountObjects, value::AbstractVector, data, aux_values) = true

using ..PatternMatching:ArrayPrefix

function wrap_func_call_prefix_value(p::Abstractor, cls::CountObjects, func::Function, wrappers::AbstractVector{Function}, source_values...)
    if func == from_abstract_value
        wrap_func_call_value(p, cls, func, wrappers, source_values...)
    else
        invoke(wrap_func_call_prefix_value, Tuple{Abstractor,AbstractorClass,Function,AbstractVector{Function},Vararg{Any}}, p, cls, func, wrappers, source_values...)
    end
end

to_abstract_value(p::Abstractor, ::CountObjects, source_value::AbstractVector) =
    Dict(
        p.output_keys[1] => ArrayPrefix(source_value),
        p.output_keys[2] => length(source_value)
    )

from_abstract_value(p::Abstractor, ::CountObjects, counted_items, len) =
    Dict(p.output_keys[1] => counted_items[1:min(len, length(counted_items))])

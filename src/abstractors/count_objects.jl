

struct CountObjects <: AbstractorClass end

CountObjects(key, to_abs) = Abstractor(CountObjects(), key, to_abs, !to_abs)
priority(::CountObjects) = 10
abs_keys(::CountObjects) = ["length", "counted"]

check_task_value(::CountObjects, value::AbstractSet, data, aux_values) = !isempty(value)

using ..PatternMatching: SubSet

function wrap_func_call_prefix_value(
    p::Abstractor{CountObjects},
    func::Function,
    wrappers::AbstractVector{Function},
    source_values...,
)
    if func == from_abstract_value
        wrap_func_call_value(p, func, wrappers, source_values...)
    else
        invoke(
            wrap_func_call_prefix_value,
            Tuple{Abstractor,Function,AbstractVector{Function},Vararg{Any}},
            p,
            func,
            wrappers,
            source_values...,
        )
    end
end

function to_abstract_value(p::Abstractor{CountObjects}, source_value::AbstractSet)
    if p.from_output
    Dict(p.output_keys[2] => SubSet(source_value), p.output_keys[1] => length(source_value))
    else
        Dict(p.output_keys[2] => source_value, p.output_keys[1] => length(source_value))
    end
end

function from_abstract_value(p::Abstractor{CountObjects}, len, counted_items)
    if length(counted_items) > len
        Dict(p.output_keys[1] => Set(counted_items[1:min(len, length(counted_items))]))
    else
        Dict(p.output_keys[1] => Set(counted_items))
    end
end

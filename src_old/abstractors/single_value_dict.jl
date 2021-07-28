

struct SingleValueDict <: AbstractorClass end

SingleValueDict(key, to_abs) = Abstractor(SingleValueDict(), key, to_abs, !to_abs)
abs_keys(::SingleValueDict) = ["values_dict"]
priority(::SingleValueDict) = 14

init_create_check_data(::SingleValueDict, key, solution) = Dict("effective" => false)

function check_task_value(::SingleValueDict, value::AbstractSet, data, aux_values)
    data["effective"] |= length(value) > 1
    return true
end

to_abstract_value(p::Abstractor{SingleValueDict}, source_value) =
    Dict(p.output_keys[1] => Dict(hash(v) => v for v in source_value))


function wrap_func_call_dict_value(
    p::Abstractor{SingleValueDict},
    func::Function,
    wrappers::AbstractVector{Function},
    source_values...,
)
    if func == from_abstract_value
        wrap_func_call_value(p, func, wrappers, source_values...)
    else
        invoke(
            wrap_func_call_dict_value,
            Tuple{Abstractor,Function,AbstractVector{Function},Vararg{Any}},
            p,
            func,
            wrappers,
            source_values...,
        )
    end
end

function from_abstract_value(p::Abstractor{SingleValueDict}, data)
    return Dict(p.output_keys[1] => Set(values(data)))
end

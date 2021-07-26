

struct UnpackDict <: AbstractorClass end

abs_keys(::UnpackDict) = ["dict_values"]
_key_for_group(cls::UnpackDict, key, group) = key * "|" * abs_keys(cls)[1] * "|$group"
abs_keys(cls::UnpackDict, key::String, groups) = [_key_for_group(cls, key, group) for group in groups]
priority(::UnpackDict) = 14


init_create_check_data(::UnpackDict, key, solution) = Dict{Any,Any}("keys" => nothing)

function check_task_value(::UnpackDict, value::AbstractDict, data, aux_values)
    if isnothing(data["keys"])
        data["keys"] = Set(keys(value))
        return true
    else
        return issetequal(data["keys"], keys(value))
    end
end

wrap_check_task_value(cls::UnpackDict, value::AbstractDict, data, aux_values) =
    check_task_value(cls, value, data, aux_values)

function create_abstractors(cls::UnpackDict, from_output, data, key, found_aux_keys)
    data["keys"] = collect(data["keys"])
    [(
        priority(cls),
        (
            to_abstract = Abstractor(
                cls,
                true,
                from_output,
                detail_keys(cls, key),
                abs_keys(cls, key, data["keys"]),
                String[],
                data,
            ),
            from_abstract = Abstractor(
                cls,
                false,
                from_output,
                abs_keys(cls, key, data["keys"]),
                detail_keys(cls, key),
                String[],
                data,
            ),
        ),
    )]
end


needed_input_keys(p::Abstractor{UnpackDict}) = p.to_abstract ? p.input_keys : []

to_abstract_value(p::Abstractor{UnpackDict}, source_value::Dict) =
    Dict(_key_for_group(p.cls, p.input_keys[1], group) => value for (group, value) in source_value)


function wrap_func_call_dict_value(
    p::Abstractor{UnpackDict},
    func::Function,
    wrappers::AbstractVector{Function},
    source_values...,
)
    if func == to_abstract_value
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

function from_abstract_value(p::Abstractor{UnpackDict}, groups_values...)
    result = Dict(group => value for (group, value) in zip(p.params["keys"], groups_values) if !isnothing(value))
    return isempty(result) ? Dict() : Dict(p.output_keys[1] => result)
end

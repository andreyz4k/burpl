

struct GroupMin <: ComputeFunctionClass end

@memoize abs_keys(::GroupMin) = ["group_min"]

wrap_check_task_value(cls::GroupMin, value::AbstractDict, data, aux_values) =
    check_task_value(cls, value, data, aux_values)

check_task_value(::GroupMin, value::AbstractDict, data, aux_values) =
    all(isa(v, Int64) for v in values(value))

wrap_func_call_dict_value(p::Abstractor, cls::GroupMin, func, source_values...) =
    func(p, cls, source_values...)

function to_abstract_value(p::Abstractor, ::GroupMin, source_value::AbstractDict)
    Dict(p.output_keys[1] => findmin(source_value)[2])
end

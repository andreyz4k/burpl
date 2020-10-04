

struct GroupMax <: ComputeFunctionClass end

@memoize abs_keys(::GroupMax) = ["group_max"]

wrap_check_task_value(cls::GroupMax, value::AbstractDict, data, aux_values) =
    check_task_value(cls, value, data, aux_values)

check_task_value(::GroupMax, value::AbstractDict, data, aux_values) =
    all(isa(v, Int64) for v in values(value))

wrap_func_call_dict_value(p::Abstractor, cls::GroupMax, func::Function, wrappers::AbstractVector{Function}, source_values...) =
    wrap_func_call_value(p, cls, func, wrappers, source_values...)

function to_abstract_value(p::Abstractor, ::GroupMax, source_value::AbstractDict)
    Dict(p.output_keys[1] => findmax(source_value)[2])
end

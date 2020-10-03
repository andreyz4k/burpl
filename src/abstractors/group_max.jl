

struct GroupMax <: ComputeFunctionClass end

@memoize abs_keys(::GroupMax) = ["group_max"]

wrap_check_task_value(cls::GroupMax, value::AbstractDict, data, aux_values) =
    check_task_value(cls, value, data, aux_values)

check_task_value(::GroupMax, value::AbstractDict, data, aux_values) =
    all(isa(v, Int64) for v in values(value))

wrap_to_abstract_value(p::Abstractor, cls::GroupMax, source_value::AbstractDict, aux_values...) =
    to_abstract_value(p, cls, source_value, aux_values...)

function to_abstract_value(p::Abstractor, ::GroupMax, source_value::AbstractDict)
    println("get group max")
    Dict(p.output_keys[1] => findmax(source_value)[2])
end

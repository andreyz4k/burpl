

struct GroupMin <: ComputeFunctionClass end

@memoize abs_keys(cls::GroupMin) = ["group_min"]

wrap_check_task_value(cls::GroupMin, value::AbstractDict, data, aux_values) =
    check_task_value(cls, value, data, aux_values)

check_task_value(cls::GroupMin, value::AbstractDict, data, aux_values) =
    all(isa(v, Int64) for v in values(value))

wrap_to_abstract_value(p::Abstractor, cls::GroupMin, source_value::AbstractDict, aux_values) =
    to_abstract_value(p, cls, source_value, aux_values)

function to_abstract_value(p::Abstractor, cls::GroupMin, source_value::AbstractDict, aux_values)
    println("get group min")
    Dict(p.output_keys[1] => findmin(source_value)[2])
end

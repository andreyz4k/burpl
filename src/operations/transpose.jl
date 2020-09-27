
struct Transpose <: AbstractorClass end

Transpose(key, to_abs) = Abstractor(Transpose(), key, to_abs)
@memoize abs_keys(cls::Transpose) = ["transposed"]
@memoize priority(::Transpose) = 10

init_create_check_data(cls::Transpose, key, solution) = Dict("effective" => false)

function check_task_value(cls::Transpose, value::AbstractArray{Int,2}, data, aux_values)
    if !data["effective"]
        transpose
        data["effective"] = !any(val == transpose(value) for val in aux_values)
    end
    true
end

create_abstractors(cls::Transpose, data, key, found_aux_keys) =
    data["effective"] ? invoke(create_abstractors, Tuple{AbstractorClass,Any,Any,Any}, cls, data, key, found_aux_keys) : []


get_aux_values_for_task(cls::Transpose, task_data, key, solution) =
    in(key, solution.unfilled_fields) ?
    values(filter(kv -> isa(kv[2], Array{Int,2}) && kv[1] != key &&
                        (in(kv[1], solution.unfilled_fields) ||
                         in(kv[1], solution.transformed_fields)),
                  task_data)) :
    values(filter(kv -> isa(kv[2], Array{Int,2}) && kv[1] != key &&
                        !in(kv[1], solution.unfilled_fields) &&
                        !in(kv[1], solution.transformed_fields),
                  task_data))

to_abstract_value(p::Abstractor, cls::Transpose, source_value::AbstractArray{Int,2}, aux_values) =
    Dict(p.output_keys[1] => collect(transpose(source_value)))

from_abstract_value(p::Abstractor, cls::Transpose, source_values) =
    Dict(p.output_keys[1] => collect(transpose(source_values[1])))

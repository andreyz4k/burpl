
struct Transpose <: AbstractorClass end

Transpose(key, to_abs) = Abstractor(Transpose(), key, to_abs)
abs_keys(::Transpose) = ["transposed"]
priority(::Transpose) = 10

init_create_check_data(::Transpose, key, solution) = Dict("effective" => false)

function check_task_value(::Transpose, value::AbstractArray{Int,2}, data, aux_values)
    data["effective"] |= !any(val == transpose(value) for val in aux_values)
    true
end


get_aux_values_for_task(::Transpose, task_data, key, solution) =
    in(key, solution.unfilled_fields) ?
    values(filter(kv -> isa(kv[2], Array{Int,2}) && kv[1] != key &&
                        (in(kv[1], solution.unfilled_fields) ||
                         in(kv[1], solution.transformed_fields)),
                  task_data)) :
    values(filter(kv -> isa(kv[2], Array{Int,2}) && kv[1] != key &&
                        !in(kv[1], solution.unfilled_fields) &&
                        !in(kv[1], solution.transformed_fields),
                  task_data))

to_abstract_value(p::Abstractor, ::Transpose, source_value::AbstractArray{Int,2}) =
    Dict(p.output_keys[1] => collect(transpose(source_value)))

from_abstract_value(p::Abstractor, ::Transpose, source_value) =
    Dict(p.output_keys[1] => collect(transpose(source_value)))

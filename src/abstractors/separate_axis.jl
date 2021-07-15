
struct SeparateAxis <: AbstractorClass end
abs_keys(::SeparateAxis) = ["coord1", "coord2"]

init_create_check_data(::SeparateAxis, key, solution) = Dict("effective" => false, "effective_parts" => (false, false))

function check_task_value(::SeparateAxis, value::Tuple{OInt,OInt}, data, aux_values)
    data["effective_parts"] =
        (data["effective_parts"][1] || (value[1] != 0), data["effective_parts"][2] || (value[2] != 0))
    data["effective"] = data["effective_parts"][1] && data["effective_parts"][2]
    true
end

function check_task_value(c::SeparateAxis, value::AbstractVector{Tuple{OInt,OInt}}, data, aux_values)
    all(check_task_value(c, v, data, aux_values) for v in value)
end

to_abstract_value(p::Abstractor{SeparateAxis}, source_value::Tuple{OInt,OInt}) =
    Dict(p.output_keys[1] => (source_value[1], OInt(0)), p.output_keys[2] => (OInt(0), source_value[2]))

to_abstract_value(p::Abstractor{SeparateAxis}, source_value::AbstractVector{Tuple{OInt,OInt}}) = Dict(
    p.output_keys[1] => [(point[1], OInt(0)) for point in source_value],
    p.output_keys[2] => [(OInt(0), point[2]) for point in source_value],
)

from_abstract_value(p::Abstractor{SeparateAxis}, coord1::Tuple{OInt,OInt}, coord2::Tuple{OInt,OInt}) =
    Dict(p.output_keys[1] => (coord1[1], coord2[2]))

from_abstract_value(
    p::Abstractor{SeparateAxis},
    coord1::AbstractVector{Tuple{OInt,OInt}},
    coord2::AbstractVector{Tuple{OInt,OInt}},
) = Dict(p.output_keys[1] => [(c1[1], c2[2]) for (c1, c2) in zip(coord1, coord2)])

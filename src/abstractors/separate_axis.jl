
struct SeparateAxis <: AbstractorClass end
abs_keys(::SeparateAxis) = ["coord1", "coord2"]

check_task_value(::SeparateAxis, value::Tuple{Int,Int}, data, aux_values) = true
check_task_value(::SeparateAxis, value::AbstractVector{Tuple{Int,Int}}, data, aux_values) = true

to_abstract_value(p::Abstractor{SeparateAxis}, source_value::Tuple{Int,Int}) =
    Dict(
        p.output_keys[1] => (source_value[1], 0),
        p.output_keys[2] => (0, source_value[2]),
    )

to_abstract_value(p::Abstractor{SeparateAxis}, source_value::AbstractVector{Tuple{Int,Int}}) =
    Dict(
        p.output_keys[1] => [(point[1], 0) for point in source_value],
        p.output_keys[2] => [(0, point[2]) for point in source_value],
    )

from_abstract_value(p::Abstractor{SeparateAxis}, coord1::Tuple{Int,Int}, coord2::Tuple{Int,Int}) =
    Dict(
        p.output_keys[1] => (coord1[1], coord2[2])
    )

from_abstract_value(p::Abstractor{SeparateAxis}, coord1::AbstractVector{Tuple{Int,Int}}, coord2::AbstractVector{Tuple{Int,Int}}) =
    Dict(
        p.output_keys[1] => [(c1[1], c2[2]) for (c1, c2) in zip(coord1, coord2)]
    )

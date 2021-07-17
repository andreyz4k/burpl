

abstract type Flip <: AbstractorClass end
struct HorisontalFlip <: Flip end
struct VerticalFlip <: Flip end

HorisontalFlip(key, to_abs) = Abstractor(HorisontalFlip(), key, to_abs, !to_abs)
VerticalFlip(key, to_abs) = Abstractor(VerticalFlip(), key, to_abs, !to_abs)
abs_keys(::HorisontalFlip) = ["flipped_horz"]
abs_keys(::VerticalFlip) = ["flipped_vert"]
priority(::Flip) = 15

init_create_check_data(::Flip, key, solution) = Dict("effective" => false)


flip(::HorisontalFlip, value::Matrix{Int}) = value[:, end:-1:1]
flip(::VerticalFlip, value::Matrix{Int}) = value[end:-1:1, :]

function check_task_value(cls::Flip, value::Matrix{Int}, data, aux_values)
    flipped = flip(cls, value)
    data["effective"] |= value != flipped && !any(val == flipped for val in aux_values)
    true
end


get_aux_values_for_task(::Flip, task_data, key, solution) =
    in(key, solution.unfilled_fields) ?
    values(
        filter(
            kv ->
                isa(kv[2], Matrix{Int}) &&
                    kv[1] != key &&
                    (in(kv[1], solution.unfilled_fields) || in(kv[1], solution.transformed_fields)),
            task_data,
        ),
    ) :
    values(
        filter(
            kv ->
                isa(kv[2], Matrix{Int}) &&
                    kv[1] != key &&
                    !in(kv[1], solution.unfilled_fields) &&
                    !in(kv[1], solution.transformed_fields),
            task_data,
        ),
    )

to_abstract_value(p::Abstractor{<:Flip}, source_value::Matrix{Int}) =
    Dict(p.output_keys[1] => collect(flip(p.cls, source_value)))

from_abstract_value(p::Abstractor{<:Flip}, source_value) = Dict(p.output_keys[1] => collect(flip(p.cls, source_value)))


struct BackgroundColor <: AbstractorClass end


BackgroundColor(key, to_abs) = Abstractor(BackgroundColor(), key, to_abs)
@memoize abs_keys(cls::BackgroundColor) = ["bgr_grid", "background"]
@memoize priority(cls::BackgroundColor) = 2

check_task_value(cls::BackgroundColor, value::AbstractArray{Int,2}, data, aux_values) =
    minimum(value) > -1

using ..PatternMatching:make_either

function to_abstract_value(p::Abstractor, cls::BackgroundColor, source_value::AbstractArray{Int,2}, aux_values)
    grid_size = *(size(source_value)...)
    options = filter(color -> sum(source_value .== color) >= grid_size / (color == 0 ? 4 : 3), 0:9)
    return make_either(p.output_keys, [
        (map(c -> c == color ? -1 : c, source_value), color)
        for color in options])
end

from_abstract_value(p::Abstractor, cls::BackgroundColor, source_values) =
    Dict(
        p.output_keys[1] => map(c -> c == -1 ? source_values[2] : c, source_values[1])
    )

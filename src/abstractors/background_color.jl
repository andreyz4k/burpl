
struct BackgroundColor <: AbstractorClass end


BackgroundColor(key, to_abs) = Abstractor(BackgroundColor(), key, to_abs)
@memoize abs_keys(::BackgroundColor) = ["bgr_grid", "background"]
@memoize priority(::BackgroundColor) = 7

check_task_value(::BackgroundColor, value::AbstractArray{Int,2}, data, aux_values) =
    minimum(value) > -1

using ..PatternMatching:make_either

function to_abstract_value(p::Abstractor, ::BackgroundColor, source_value::AbstractArray{Int,2})
    grid_size = *(size(source_value)...)
    options = filter(color -> sum(source_value .== color) >= grid_size / (color == 0 ? 4 : 3), 0:9)
    return make_either(p.output_keys, [
        (map(c -> c == color ? -1 : c, source_value), color)
        for color in options])
end

from_abstract_value(p::Abstractor, ::BackgroundColor, bgr_grid, background) =
    Dict(
        p.output_keys[1] => map(c -> c == -1 ? background : c, bgr_grid)
    )

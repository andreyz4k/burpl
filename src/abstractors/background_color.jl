
struct BackgroundColor <: AbstractorClass end


BackgroundColor(key, to_abs) = Abstractor(BackgroundColor(), key, to_abs)
abs_keys(::BackgroundColor) = ["background", "bgr_grid"]
priority(::BackgroundColor) = 7

function check_task_value(::BackgroundColor, value::AbstractArray{OInt,2}, data, aux_values)
    if minimum(value) == OInt(-1)
        return false
    end
    grid_size = *(size(value)...)
    if length(filter(color -> sum(value .== color) >= grid_size / (color == OInt(0) ? 4 : 3), OInt(0):OInt(9))) == 0
        return false
    end
    return true
end
using ..PatternMatching: make_either
using ..ObjectPrior: Color

function to_abstract_value(p::Abstractor{BackgroundColor}, source_value::AbstractArray{OInt,2})
    grid_size = *(size(source_value)...)
    options = filter(color -> sum(source_value .== color) >= grid_size / (color == OInt(0) ? 4 : 3), OInt(0):OInt(9))
    # options = filter(color -> sum(source_value .== color) >= (color == 0 ? grid_size / 3 : 0), 0:9)
    return make_either(
        p.output_keys,
        [(Color(color), map(c -> c == color ? OInt(-1) : c, source_value)) for color in options],
    )
end

from_abstract_value(p::Abstractor{BackgroundColor}, background, bgr_grid) =
    Dict(p.output_keys[1] => map(c -> c == OInt(-1) ? background.value : c, bgr_grid))

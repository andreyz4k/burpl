

struct AlignedWithBorder <: ComputeFunctionClass end
abs_keys(::AlignedWithBorder) = ["border_alignment"]
aux_keys(::AlignedWithBorder) = ["grid_size"]
priority(::AlignedWithBorder) = 8

check_task_value(::AlignedWithBorder, ::Object, data, aux_values) = true

function to_abstract_value(p::Abstractor, ::AlignedWithBorder, source_value::Object, grid_size::Tuple{Int64,Int64})
    x = 0
    if source_value.position[1] == 1
        x += 1
    end
    if source_value.position[1] + size(source_value.shape)[1] - 1 == grid_size[1]
        x -= 1
    end
    y = 0
    if source_value.position[2] == 1
        y += 1
    end
    if source_value.position[2] + size(source_value.shape)[2] - 1 == grid_size[2]
        y -= 1
    end
    Dict(p.output_keys[1] => (x, y))
end

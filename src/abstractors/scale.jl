

struct Scale <: AbstractorClass end


Scale(key, to_abs) = Abstractor(Scale(), key, to_abs, !to_abs)


abs_keys(::Scale) = ["scaled", "scale_factor"]

function check_task_value(::Scale, value::Matrix{Int}, data, aux_values)
    for scale_factor = 2:6
        if size(value) .% scale_factor != (0, 0)
            continue
        end
        good = true
        for i = 0:size(value)[1]÷scale_factor-1, j = 0:size(value)[2]÷scale_factor-1
            x1 = 1 + i * scale_factor
            y1 = 1 + j * scale_factor
            color = value[x1, y1]
            if !all(value[x1:x1+scale_factor-1, y1:y1+scale_factor-1] .== color)
                good = false
                break
            end
        end
        if good
            return true
        end
    end
    false
end

function to_abstract_value(p::Abstractor{Scale}, source_value::Matrix{Int})
    options = []
    for scale_factor = 2:6
        if size(source_value) .% scale_factor != (0, 0)
            continue
        end
        good = true
        scaled_size = size(source_value) .÷ scale_factor
        result = Array{Int}(undef, scaled_size...)

        for i = 0:scaled_size[1]-1, j = 0:scaled_size[2]-1
            x1 = 1 + i * scale_factor
            y1 = 1 + j * scale_factor
            color = source_value[x1, y1]
            result[i+1, j+1] = color
            if !all(source_value[x1:x1+scale_factor-1, y1:y1+scale_factor-1] .== color)
                good = false
                break
            end
        end
        if good
            push!(options, (result, scale_factor))
        end
    end
    return make_either(p.output_keys, options)
end

function from_abstract_value(p::Abstractor{Scale}, scaled_grid::Matrix{Int}, scale_factor::Int)
    scaled_size = size(scaled_grid) .* scale_factor
    result = Array{Int}(undef, scaled_size...)
    for i = 0:size(scaled_grid)[1]-1, j = 0:size(scaled_grid)[2]-1
        x1 = 1 + i * scale_factor
        y1 = 1 + j * scale_factor
        result[x1:x1+scale_factor-1, y1:y1+scale_factor-1] .= scaled_grid[i+1, j+1]
    end
    Dict(p.output_keys[1] => result)
end

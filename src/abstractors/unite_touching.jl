

struct UniteTouching <: AbstractorClass end

UniteTouching(key, to_abs) = Abstractor(UniteTouching(), key, to_abs)
@memoize abs_keys(p::UniteTouching) = ["united_touch"]

init_create_check_data(cls::UniteTouching, key, solution) = Dict("effective" => false)

points_around(p) = [(i, j) for i in p[1] - 1:p[1] + 1, j in p[2] - 1:p[2] + 1]

point_in_obj(obj, p) = point_in_rect(p, obj.position, obj.position .+ size(obj.shape) .- (1, 1)) &&
                obj.shape[p[1] - obj.position[1] + 1, p[2] - obj.position[2] + 1] != -1

function _is_touching(a::Object, b::Object)
    intersection = max.(a.position .- (1, 1), b.position .- (1, 1)),
        min.(a.position .+ size(a.shape), b.position .+ size(b.shape))
    for i in intersection[1][1]:intersection[2][1], j in intersection[1][2]:intersection[2][2]
        if point_in_obj(a, (i, j)) && any(point_in_obj(b, p) for p in points_around((i, j)))
            return true
        end
    end
    false
end

function check_task_value(cls::UniteTouching, value::AbstractVector{Object}, data, aux_values)
    for (i, a) in enumerate(value), b in view(value, i + 1:length(value))
        if get_color(a) == get_color(b) && _is_touching(a, b)
            data["effective"] = true
            break
        end
    end
    true
end

function to_abstract_value(p::Abstractor, cls::UniteTouching, source_value::AbstractVector{Object}, aux_values)
    out = Object[]
    merged = Set()
    for (i, obj) in enumerate(source_value)
        if in(obj, merged)
            continue
        end
        for obj2 in view(source_value, i + 1:length(source_value))
            if in(obj2, merged)
                continue
            end
            if get_color(obj) == get_color(obj2) && _is_touching(obj, obj2)
                obj = _merge_objects(obj, obj2)
                push!(merged, obj2)
            end
        end
        push!(out, obj)
    end
    return Dict(p.output_keys[1] => out)
end

function from_abstract_value(p::Abstractor, cls::UniteTouching, source_values)
    return Dict(p.output_keys[1] => source_values[1])
end

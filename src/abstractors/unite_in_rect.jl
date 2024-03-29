

struct UniteInRect <: AbstractorClass end

UniteInRect(key, to_abs) = Abstractor(UniteInRect(), key, to_abs, !to_abs)
abs_keys(::UniteInRect) = ["united_rect"]
priority(::UniteInRect) = 12

init_create_check_data(::UniteInRect, key, solution) = Dict("effective" => false)

_is_in(a::Object, b::Object) =
    all(a.position .<= b.position) && all(a.position .+ size(a.shape) .>= b.position .+ size(b.shape))

function check_task_value(::UniteInRect, value::AbstractSet{Object}, data, aux_values)
    value = collect(value)
    for (i, a) in enumerate(value), b in view(value, i+1:length(value))
        if get_color(a) == get_color(b) && (_is_in(a, b) || _is_in(b, a))
            data["effective"] = true
            break
        end
    end
    true
end

function to_abstract_value(p::Abstractor{UniteInRect}, source_value::AbstractSet{Object})
    out = Set{Object}()
    merged = Set()
    source_value = collect(source_value)
    for (i, obj) in enumerate(source_value)
        if in(obj, merged)
            continue
        end
        complete = false
        while !complete
            complete = true
            for obj2 in view(source_value, i+1:length(source_value))
                if in(obj2, merged)
                    continue
                end
                if get_color(obj) == get_color(obj2) && (_is_in(obj, obj2) || _is_in(obj2, obj))
                    obj = _merge_objects(obj, obj2)
                    push!(merged, obj2)
                    complete = false
                    break
                end
            end
        end
        push!(out, obj)
    end
    return Dict(p.output_keys[1] => out)
end

from_abstract_value(p::Abstractor{UniteInRect}, source_value) = Dict(p.output_keys[1] => source_value)

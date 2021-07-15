

abstract type Symmetry <: AbstractorClass end
struct VerticalSymmetry <: Symmetry end
struct HorisontalSymmetry <: Symmetry end

abs_keys(::VerticalSymmetry) = ["vert_kernel", "vert_is_left", "vert_keep_pivot_point"]
abs_keys(::HorisontalSymmetry) = ["horz_kernel", "horz_is_top", "horz_keep_pivot_point"]

init_create_check_data(::Symmetry, key, solution) = Dict("effective" => false)

check_task_value(p::Symmetry, value::AbstractVector, data, aux_values) =
    all(wrap_check_task_value(p, v, data, aux_values) for v in value)

check_task_value(p::Symmetry, value::Object, data, aux_values) = check_task_value(p, value.shape, data, aux_values)

function check_task_value(::VerticalSymmetry, value::AbstractArray{OInt,2}, data, aux_values)
    data["effective"] |= size(value)[1] > 1
    value[end:-1:1, :] == value
end

function check_task_value(::HorisontalSymmetry, value::AbstractArray{OInt,2}, data, aux_values)
    data["effective"] |= size(value)[2] > 1
    value[:, end:-1:1] == value
end

function to_abstract_value(p::Abstractor{<:Symmetry}, source_value::AbstractVector)
    res = Dict(k => [] for k in p.output_keys)
    for obj in source_value
        for (k, v) in wrap_func_call_value_root(p, to_abstract_value, obj)
            push!(res[k], v)
        end
    end
    return res
end

using ..PatternMatching: unpack_value, AuxValue

function _wrap_aux_values(keys, result)
    if isa(result[keys[1]], Either)
        Dict(keys[1] => result[keys[1]], keys[2] => AuxValue(result[keys[2]]), keys[3] => AuxValue(result[keys[3]]))
    else
        # Dict(
        #     keys[1] => result[keys[1]],
        #     keys[2] => isa(result[keys[2]], Either) ? unwrap_matcher(result[keys[2]])[1] : result[keys[2]],
        #     keys[3] => isa(result[keys[3]], Either) ? unwrap_matcher(result[keys[3]])[1] : result[keys[3]],
        # )
        result
    end
end
function to_abstract_value(p::Abstractor{VerticalSymmetry}, source_value::Object)
    res = to_abstract_value(p, source_value.shape)
    return _wrap_aux_values(
        p.output_keys,
        make_either(
            p.output_keys,
            [
                (
                    Object(
                        opt[p.output_keys[1]],
                        (
                            source_value.position[1] +
                            !opt[p.output_keys[2]] * (size(source_value.shape)[1] - size(opt[p.output_keys[1]])[1]),
                            source_value.position[2],
                        ),
                    ),
                    opt[p.output_keys[2]],
                    opt[p.output_keys[3]],
                ) for opt in unpack_value(
                    Dict(
                        p.output_keys[1] => res[p.output_keys[1]],
                        p.output_keys[2] =>
                            isa(res[p.output_keys[2]], AuxValue) ? unwrap_matcher(res[p.output_keys[2]])[1] :
                            res[p.output_keys[2]],
                        p.output_keys[3] =>
                            isa(res[p.output_keys[3]], AuxValue) ? unwrap_matcher(res[p.output_keys[3]])[1] :
                            res[p.output_keys[3]],
                    ),
                )
            ],
        ),
    )
end

function to_abstract_value(p::Abstractor{VerticalSymmetry}, source_value::AbstractArray{OInt,2})
    anchor = ((size(source_value)[1] - 1) / 2) + 1
    keep_pivot_point = anchor % 1 == 0
    return _wrap_aux_values(
        p.output_keys,
        make_either(
            p.output_keys,
            [
                (source_value[1:Int(floor(anchor)), :], true, keep_pivot_point),
                (source_value[Int(ceil(anchor)):end, :], false, keep_pivot_point),
            ],
        ),
    )
end

function to_abstract_value(p::Abstractor{HorisontalSymmetry}, source_value::Object)
    res = to_abstract_value(p, source_value.shape)
    return _wrap_aux_values(
        p.output_keys,
        make_either(
            p.output_keys,
            [
                (
                    Object(
                        opt[p.output_keys[1]],
                        (
                            source_value.position[1],
                            source_value.position[2] +
                            !opt[p.output_keys[2]] * (size(source_value.shape)[2] - size(opt[p.output_keys[1]])[2]),
                        ),
                    ),
                    opt[p.output_keys[2]],
                    opt[p.output_keys[3]],
                ) for opt in unpack_value(
                    Dict(
                        p.output_keys[1] => res[p.output_keys[1]],
                        p.output_keys[2] =>
                            isa(res[p.output_keys[2]], AuxValue) ? unwrap_matcher(res[p.output_keys[2]])[1] :
                            res[p.output_keys[2]],
                        p.output_keys[3] =>
                            isa(res[p.output_keys[3]], AuxValue) ? unwrap_matcher(res[p.output_keys[3]])[1] :
                            res[p.output_keys[3]],
                    ),
                )
            ],
        ),
    )
end

function to_abstract_value(p::Abstractor{HorisontalSymmetry}, source_value::AbstractArray{OInt,2})
    anchor = ((size(source_value)[2] - 1) / 2) + 1
    keep_pivot_point = anchor % 1 == 0
    return _wrap_aux_values(
        p.output_keys,
        make_either(
            p.output_keys,
            [
                (source_value[:, 1:Int(floor(anchor))], true, keep_pivot_point),
                (source_value[:, Int(ceil(anchor)):end], false, keep_pivot_point),
            ],
        ),
    )
end


function from_abstract_value(
    p::Abstractor{VerticalSymmetry},
    source_value::AbstractArray{OInt,2},
    is_left::Bool,
    keep_pivot_point::Bool,
)
    height = size(source_value)[1] * 2 - keep_pivot_point
    res = Array{OInt}(undef, height, size(source_value)[2])
    if is_left
        res[1:size(source_value)[1], :] = source_value
        res[end:-1:end-size(source_value)[1]+1, :] = source_value
    else
        res[size(source_value)[1]:-1:1, :] = source_value
        res[end-size(source_value)[1]+1:end, :] = source_value
    end
    return Dict(p.output_keys[1] => res)
end

function from_abstract_value(
    p::Abstractor{VerticalSymmetry},
    source_value::Object,
    is_left::Bool,
    keep_pivot_point::Bool,
)
    res_shape = from_abstract_value(p, source_value.shape, is_left, keep_pivot_point)[p.output_keys[1]]
    pos = source_value.position
    if !is_left
        pos = (pos[1] - size(res_shape)[1] + size(source_value.shape)[1], pos[2])
    end
    return Dict(p.output_keys[1] => Object(res_shape, pos))
end

function from_abstract_value(
    p::Abstractor{HorisontalSymmetry},
    source_value::AbstractArray{OInt,2},
    is_top::Bool,
    keep_pivot_point::Bool,
)
    width = size(source_value)[2] * 2 - keep_pivot_point
    res = Array{OInt}(undef, size(source_value)[1], width)
    if is_top
        res[:, 1:size(source_value)[2]] = source_value
        res[:, end:-1:end-size(source_value)[2]+1] = source_value
    else
        res[:, size(source_value)[2]:-1:1] = source_value
        res[:, end-size(source_value)[2]+1:end] = source_value
    end
    return Dict(p.output_keys[1] => res)
end

function from_abstract_value(
    p::Abstractor{HorisontalSymmetry},
    source_value::Object,
    is_top::Bool,
    keep_pivot_point::Bool,
)
    res_shape = from_abstract_value(p, source_value.shape, is_top, keep_pivot_point)[p.output_keys[1]]
    pos = source_value.position
    if !is_top
        pos = (pos[1], pos[2] - size(res_shape)[2] + size(source_value.shape)[2])
    end
    return Dict(p.output_keys[1] => Object(res_shape, pos))
end

from_abstract_value(
    p::Abstractor{<:Symmetry},
    source_value::AbstractArray{Object},
    is_left::AbstractArray{Bool},
    keep_pivot_point::AbstractArray{Bool},
) = Dict(
    p.output_keys[1] => [
        wrap_func_call_value_root(p, from_abstract_value, v, l, k) for
        (v, l, k) in zip(source_value, is_left, keep_pivot_point)
    ],
)

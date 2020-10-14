
struct IncParam <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    shift::Union{Int64,Tuple{Int64,Int64}}
    complexity::Float64
    IncParam(key, inp_key, shift) = new([inp_key], [key, key * "|inc_shift"], shift, 1)
end

Base.show(io::IO, op::IncParam) = print(io, "IncParam(\"", op.output_keys[1], "\", \"", op.input_keys[1], "\", ", op.shift, ")")

Base.:(==)(a::IncParam, b::IncParam) = a.output_keys == b.output_keys && a.input_keys == b.input_keys && a.shift == b.shift
Base.hash(op::IncParam, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h) + hash(op.shift, h)

function (op::IncParam)(task_data)
    output_value = shift_value(task_data[op.input_keys[1]], op.shift)
    data = update_value(task_data, op.output_keys[1], output_value)
    update_value(data, op.output_keys[2], op.shift)
end

_get_diff_value(val1, val2) = val1 .- val2
_get_diff_value(val1::Vector, val2::Vector) = _get_diff_value(val1[1], val2[1])
function _get_diff_value(val1::Dict, val2::Dict)
    key, v1 = first(val1)
    if !haskey(val2, key)
        return nothing
    end
    _get_diff_value(v1, val2[key])
end

_init_shift(input_value, output_value, _, _) =
    filter(v -> !isnothing(v), [_get_diff_value(value, input_value) for value in unpack_value(output_value) if value != input_value])

_shifted_filter(shift, input_value, output_value, _) = !isnothing(common_value(apply_func(input_value, (x, y) -> x .+ y, shift), output_value))


find_shifted_key(taskdata::Vector{Dict{String,Any}}, field_info, invalid_sources::AbstractSet{String}, key::String) =
    find_matching_for_key(taskdata, field_info, invalid_sources, key, _init_shift, _shifted_filter, IncParam, (_, _) -> true)

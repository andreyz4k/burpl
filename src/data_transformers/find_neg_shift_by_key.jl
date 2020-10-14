
struct DecByParam <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    complexity::Float64
    DecByParam(key, inp_key, shift_key) = new([inp_key, shift_key], [key], 1)
end

Base.show(io::IO, op::DecByParam) = print(io, "DecByParam(\|", op.output_keys[1], "\", \"", op.input_keys[1], "\", \"", op.input_keys[2], "\")")

Base.:(==)(a::DecByParam, b::DecByParam) = a.output_keys == b.output_keys && a.input_keys == b.input_keys
Base.hash(op::DecByParam, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h)

neg_shift_value(value, shift) = value .- shift
neg_shift_value(value::AbstractVector, shift) = [neg_shift_value(v, shift) for v in value]
neg_shift_value(value::Dict, shift) = Dict(key => neg_shift_value(val, shift) for (key, val) in value)

function (op::DecByParam)(task_data)
    output_value = neg_shift_value(task_data[op.input_keys[1]], task_data[op.input_keys[2]])
    update_value(task_data, op.output_keys[1], output_value)
end

_shifted_neg_key_filter(shift_key, input_value, output_value, task_data) = haskey(task_data, shift_key) &&
                         !isnothing(common_value(apply_func(input_value, (x, y) -> x .- y, task_data[shift_key]), output_value))

find_neg_shifted_by_key(taskdata::Vector{Dict{String,Any}}, field_info, invalid_sources::AbstractSet{String}, key::String) =
    find_matching_for_key(taskdata, field_info, invalid_sources, key, _init_shift_keys, _shifted_neg_key_filter, DecByParam, _check_effective_shift_key)

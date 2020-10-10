
struct IncByParam <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    complexity::Float64
    IncByParam(key, inp_key, shift_key) = new([inp_key, shift_key], [key], 1)
end

Base.show(io::IO, op::IncByParam) = print(io, "IncByParam(", op.output_keys[1], ", ", op.input_keys[1], ", ", op.input_keys[2], ")")

Base.:(==)(a::IncByParam, b::IncByParam) = a.output_keys == b.output_keys && a.input_keys == b.input_keys
Base.hash(op::IncByParam, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h)

shift_value(value, shift) = value .+ shift
shift_value(value::AbstractVector, shift) = [shift_value(v, shift) for v in value]
shift_value(value::Dict, shift) = Dict(key => shift_value(val, shift) for (key, val) in value)

function (op::IncByParam)(task_data)
    output_value = shift_value(task_data[op.input_keys[1]], task_data[op.input_keys[2]])
    update_value(task_data, op.output_keys[1], output_value)
end

_init_shift_keys(_, _, task_data, invalid_sources) =
    [key for (key, value) in task_data if !in(key, invalid_sources) && isa(value, Union{Int64,Tuple{Int64,Int64}})]

_shifted_key_filter(shift_key, input_value, output_value, task_data) = haskey(task_data, shift_key) &&
                         !isnothing(common_value(apply_func(input_value, (x, y) -> x .+ y, task_data[shift_key]), output_value))

_check_effective_shift_key(shift_key, taskdata) = any(task_data[shift_key] != 0 for task_data in taskdata)

find_shifted_by_key(taskdata::Vector{Dict{String,Any}}, field_info, invalid_sources::AbstractSet{String}, key::String) =
    find_matching_for_key(taskdata, field_info, invalid_sources, key, _init_shift_keys, _shifted_key_filter, IncByParam, _check_effective_shift_key)

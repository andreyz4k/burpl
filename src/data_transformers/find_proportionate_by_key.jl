using ..PatternMatching:Matcher

struct MultByParam <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    complexity::Float64
    MultByParam(key, inp_key, factor_key) = new([inp_key, factor_key], [key], 1)
end

Base.show(io::IO, op::MultByParam) = print(io, "MultByParam(", op.output_keys[1], ", ", op.input_keys[1], ", ", op.input_keys[2], ")")

Base.:(==)(a::MultByParam, b::MultByParam) = a.output_keys == b.output_keys && a.input_keys == b.input_keys
Base.hash(op::MultByParam, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h)

mult_value(value, factor) = value .* factor
mult_value(value::AbstractVector, factor) = [mult_value(v, factor) for v in value]
mult_value(value::Dict, factor) = Dict(key => mult_value(val, factor) for (key, val) in value)

function (op::MultByParam)(task_data)
    output_value =  mult_value(task_data[op.input_keys[1]], task_data[op.input_keys[2]])
    update_value(task_data, op.output_keys[1], output_value)
end


_init_factor_keys(_, _, task_data, invalid_sources) =
    [key for (key, value) in task_data if !in(key, invalid_sources) && isa(value, Union{Int64,Tuple{Int64,Int64}})]

_factor_key_filter(shift_key, input_value, output_value, task_data) = haskey(task_data, shift_key) &&
                         !isnothing(common_value(apply_func(input_value, (x, y) -> x .* y, task_data[shift_key]), output_value))

_check_effective_factor_key(shift_key, taskdata) = any(task_data[shift_key] != 1 for task_data in taskdata)

find_proportionate_by_key(taskdata::Vector{Dict{String,Any}}, field_info, invalid_sources::AbstractSet{String}, key::String) =
    find_matching_for_key(taskdata, field_info, invalid_sources, key, _init_factor_keys, _factor_key_filter, MultByParam, _check_effective_factor_key)

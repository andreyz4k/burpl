
struct MultByParam <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    complexity::Float64
    MultByParam(key, inp_key, factor_key) = new([inp_key, factor_key], [key], 1)
end

Base.show(io::IO, op::MultByParam) = print(io, "MultByParam(\"", op.output_keys[1], "\", \"", op.input_keys[1], "\", \"", op.input_keys[2], "\")")

Base.:(==)(a::MultByParam, b::MultByParam) = a.output_keys == b.output_keys && a.input_keys == b.input_keys
Base.hash(op::MultByParam, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h)

mult_value(value, factor) = value .* factor
mult_value(value::AbstractVector, factor) = [mult_value(v, factor) for v in value]
mult_value(value::Dict, factor) = Dict(key => mult_value(val, factor) for (key, val) in value)

function (op::MultByParam)(task_data)
    output_value =  mult_value(task_data[op.input_keys[1]], task_data[op.input_keys[2]])
    update_value(task_data, op.output_keys[1], output_value)
end


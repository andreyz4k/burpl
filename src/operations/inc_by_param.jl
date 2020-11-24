

struct IncByParam <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    complexity::Float64
    IncByParam(key, inp_key, shift_key) = new([inp_key, shift_key], [key], 1)
end

Base.show(io::IO, op::IncByParam) = print(io, "IncByParam(\"", op.output_keys[1], "\", \"", op.input_keys[1], "\", \"", op.input_keys[2], "\")")

Base.:(==)(a::IncByParam, b::IncByParam) = a.output_keys == b.output_keys && a.input_keys == b.input_keys
Base.hash(op::IncByParam, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h)

function (op::IncByParam)(task_data)
    output_value = apply_func(task_data[op.input_keys[1]], (a, b) -> a .+ b, task_data[op.input_keys[2]])
    update_value(task_data, op.output_keys[1], output_value)
end

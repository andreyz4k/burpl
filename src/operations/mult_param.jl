
struct MultParam <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    factor::Int64
    complexity::Float64
    MultParam(key, inp_key, factor) = new([inp_key], [key, key * "|mult_factor"], factor, 1)
end

Base.show(io::IO, op::MultParam) =
    print(io, "MultParam(\"", op.output_keys[1], "\", \"", op.input_keys[1], "\", ", op.factor, ")")

Base.:(==)(a::MultParam, b::MultParam) =
    a.output_keys == b.output_keys && a.input_keys == b.input_keys && a.factor == b.factor
Base.hash(op::MultParam, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h) + hash(op.factor, h)

function (op::MultParam)(taskdata::TaskData)
    output_value = [apply_func(val, (a, b) -> a .* b, op.factor) for val in taskdata[op.input_keys[1]]]
    data = update_value(taskdata, op.output_keys[1], output_value)
    update_value(data, op.output_keys[2], fill(op.factor, length(taskdata["input"])))
end

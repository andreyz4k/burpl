
struct CopyParam <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    complexity::Float64
    CopyParam(key, inp_key) = new([inp_key], [key], 1)
end

Base.show(io::IO, op::CopyParam) = print(io, "CopyParam(\"", op.output_keys[1], "\", \"", op.input_keys[1], "\")")

Base.:(==)(a::CopyParam, b::CopyParam) = a.output_keys == b.output_keys && a.input_keys == b.input_keys
Base.hash(op::CopyParam, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h)

(op::CopyParam)(taskdata::TaskData) = update_value(taskdata, op.output_keys[1], taskdata[op.input_keys[1]])


struct IncParam <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    shift::Union{Int64,Tuple{Int64,Int64}}
    complexity::Float64
    IncParam(key, inp_key, shift) = new([inp_key], [key, key * "|inc_shift"], shift, 1)
end

Base.show(io::IO, op::IncParam) =
    print(io, "IncParam(\"", op.output_keys[1], "\", \"", op.input_keys[1], "\", ", op.shift, ")")

Base.:(==)(a::IncParam, b::IncParam) =
    a.output_keys == b.output_keys && a.input_keys == b.input_keys && a.shift == b.shift
Base.hash(op::IncParam, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h) + hash(op.shift, h)

function (op::IncParam)(taskdata::TaskData)
    output_value = [apply_func(val, (a, b) -> a .+ b, op.shift) for val in taskdata[op.input_keys[1]]]
    data = update_value(taskdata, op.output_keys[1], output_value)
    update_value(data, op.output_keys[2], fill(op.shift, num_examples(taskdata)))
end

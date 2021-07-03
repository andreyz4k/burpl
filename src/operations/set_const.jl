
struct SetConst <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    value::Any
    complexity::Float64
    SetConst(key, value) = new([], [key], value, get_complexity(value))
end

Base.show(io::IO, op::SetConst) = print(io, "SetConst(\"", op.output_keys[1], "\", ", op.value, ")")

Base.:(==)(a::SetConst, b::SetConst) = a.output_keys == b.output_keys && a.value == b.value
Base.hash(op::SetConst, h::UInt64) = hash(op.output_keys, h) + hash(op.value, h)


(op::SetConst)(taskdata::TaskData) =
    update_value(taskdata, op.output_keys[1], fill(op.value, num_examples(taskdata)))

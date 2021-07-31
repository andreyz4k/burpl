

struct Operation
    method
    input_keys::Vector
    output_keys::Vector
end

Base.show(io::IO, op::Operation) = print(io, "Operation(", op.method, ", ", op.input_keys, ", ", op.output_keys, ")")

using ..DataStructures: AbstractOperation

struct SetConst <: AbstractOperation
    type
    value
    input_keys
    output_keys
end

SetConst(type, value, output_key) = SetConst(type, value, [], [output_key])

Base.show(io::IO, op::SetConst) = print(io, "SetConst(", op.type, ", ", op.value, ", \"", op.output_keys[1], "\")")

function (op::SetConst)(task_data)
    any_entry = first(values(task_data))
    entry_len = length(any_entry.values)
    return Dict(op.output_keys[1] => Entry(op.type, fill(op.value, entry_len)))
end

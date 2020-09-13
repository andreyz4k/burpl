


module DataTransformers
using ..Complexity:get_complexity
using ..Operations:Operation

struct SetConst <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    value
    complexity::Float64
    generability
    SetConst(key, value) = new([], [key], value, get_complexity(value), 0)
end

function update_value!(data::Dict, key::String, value)
    data[key] = value
    data
end

Base.show(io::IO, op::SetConst) = print(io, "SetConst(", op.output_keys[1], ", ", op.value, ")")

Base.:(==)(a::SetConst, b::SetConst) = a.output_keys == b.output_keys && a.value == b.value

function (op::SetConst)(input_grid, output_grid, task_data)
    data = copy(task_data)
    update_value!(data, op.output_keys[1], op.value)
    output_grid, data
end

end

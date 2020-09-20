
struct SetConst <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    value
    complexity::Float64
    generability
    SetConst(key, value) = new([], [key], value, get_complexity(value), 0)
end

Base.show(io::IO, op::SetConst) = print(io, "SetConst(", op.output_keys[1], ", ", op.value, ")")

Base.:(==)(a::SetConst, b::SetConst) = a.output_keys == b.output_keys && a.value == b.value
Base.hash(op::SetConst, h::UInt64) = hash(op.output_keys, h) + hash(op.value, h)

function (op::SetConst)(task_data)
    data = update_value(task_data, op.output_keys[1], op.value)
    data
end

function find_const(taskdata::Vector{Dict{String,Any}}, _, key::String)::Vector{SetConst}
    result = nothing
    for task_data in taskdata
        if !haskey(task_data, key)
            continue
        end
        if isnothing(result)
            result = task_data[key]
        end
        possible_value = compare_values(result, task_data[key])
        if isnothing(possible_value)
            return []
        end
        result = possible_value
    end
    return [SetConst(key, value) for value in unpack_value(result)]
end

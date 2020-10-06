
struct IncParam <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    shift::Union{Int64,Tuple{Int64,Int64}}
    complexity::Float64
    generability
    IncParam(key, inp_key, shift) = new([inp_key], [key, key * "|inc_shift"], shift, 1, 0)
end

Base.show(io::IO, op::IncParam) = print(io, "IncParam(", op.output_keys[1], ", ", op.input_keys[1], ", ", op.shift, ")")

Base.:(==)(a::IncParam, b::IncParam) = a.output_keys == b.output_keys && a.input_keys == b.input_keys && a.shift == b.shift
Base.hash(op::IncParam, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h) + hash(op.shift, h)

function (op::IncParam)(task_data)
    input_value = task_data[op.input_keys[1]]
    if isa(input_value, Dict)
        output_value = Dict(key => shift_value(value, op.shift) for (key, value) in input_value)
    else
        output_value = shift_value(input_value, op.shift)
    end
    data = update_value(task_data, op.output_keys[1], output_value)
    update_value(data, op.output_keys[2], op.shift)
end

function _check_shifted(input_value, output_value, possible_shifts)
    if isempty(possible_shifts)
        for value in unpack_value(output_value)
            if value != input_value
                push!(possible_shifts, value .- input_value)
            end
        end
    else
        filter!(shift -> !isnothing(common_value(input_value .+ shift, output_value)), possible_shifts)
    end
    return !isempty(possible_shifts)
end

function find_shifted_key(taskdata::Vector{Dict{String,Any}}, invalid_sources::AbstractSet{String}, key::String)
    result = []
    for input_key in keys(taskdata[1])
        if in(input_key, invalid_sources)
            continue
        end
        good = true
        possible_shifts = []
        for task_data in taskdata
            if !haskey(task_data, input_key)
                good = false
                break
            end
            if !haskey(task_data, key)
                continue
            end
            input_value = task_data[input_key]
            out_value = task_data[key]
            if !compare_values(input_value, out_value, possible_shifts, _check_shifted, Union{Int64,Tuple{Int64,Int64}})
                good = false
                break
            end
        end
        if good
            append!(result, [IncParam(key, input_key, shift) for shift in possible_shifts])
        end
    end
    return result
end

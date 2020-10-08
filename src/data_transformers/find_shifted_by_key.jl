
struct IncByParam <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    complexity::Float64
    IncByParam(key, inp_key, shift_key) = new([inp_key, shift_key], [key], 1)
end

Base.show(io::IO, op::IncByParam) = print(io, "IncByParam(", op.output_keys[1], ", ", op.input_keys[1], ", ", op.input_keys[2], ")")

Base.:(==)(a::IncByParam, b::IncByParam) = a.output_keys == b.output_keys && a.input_keys == b.input_keys
Base.hash(op::IncByParam, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h)

shift_value(value, shift) = value .+ shift
shift_value(value::AbstractVector, shift) = [shift_value(v, shift) for v in value]

function (op::IncByParam)(task_data)
    input_value = task_data[op.input_keys[1]]
    if isa(input_value, Dict)
        output_value = Dict(key => shift_value(value, task_data[op.input_keys[2]]) for (key, value) in input_value)
    else
        output_value = shift_value(input_value, task_data[op.input_keys[2]])
    end
    update_value(task_data, op.output_keys[1], output_value)
end

function _check_shifted_key(input_value, output_value, possible_shift_keys, task_data, invalid_sources)
    if isempty(possible_shift_keys)
        for (key, value) in task_data
            if !in(key, invalid_sources) &&
                isa(value, Union{Int64,Tuple{Int64,Int64}}) &&
                    !isnothing(common_value(input_value .+ value, output_value))
                push!(possible_shift_keys, key)
            end
        end
    else
        filter!(shift_key -> haskey(task_data, shift_key) &&
                             isa(task_data[shift_key], Union{Int64,Tuple{Int64,Int64}}) &&
                             !isnothing(common_value(input_value .+ task_data[shift_key], output_value)),
                possible_shift_keys)

    end
    return !isempty(possible_shift_keys)
end

function find_shifted_by_key(taskdata::Vector{Dict{String,Any}}, invalid_sources::AbstractSet{String}, key::String)
    result = []
    for input_key in keys(taskdata[1])
        if in(input_key, invalid_sources)
            continue
        end
        good = true
        possible_shift_keys = []
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
            if !compare_values(input_value, out_value, possible_shift_keys,
                               (inp_val, out_val, candidates) ->
                                _check_shifted_key(inp_val, out_val, candidates, task_data, invalid_sources),
                               Union{Int64,Tuple{Int64,Int64}})
                good = false
                break
            end
        end
        if good
            append!(result, [IncByParam(key, input_key, shift_key) for shift_key in possible_shift_keys
                             if any(task_data[shift_key] != 0 for task_data in taskdata)])
        end
    end
    return result
end

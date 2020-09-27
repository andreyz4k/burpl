
struct IncByParam <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    complexity::Float64
    generability
    IncByParam(key, inp_key, shift_key) = new([inp_key, shift_key], [key], 1, 0)
end

Base.show(io::IO, op::IncByParam) = print(io, "IncByParam(", op.output_keys[1], ", ", op.input_keys[1], ", ", op.input_keys[2], ")")

Base.:(==)(a::IncByParam, b::IncByParam) = a.output_keys == b.output_keys && a.input_keys == b.input_keys
Base.hash(op::IncByParam, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h)

function (op::IncByParam)(task_data)
    input_value = task_data[op.input_keys[1]]
    if isa(input_value, Dict)
        output_value = Dict(key => value .+ task_data[op.input_keys[2]] for (key, value) in input_value)
    else
        output_value = input_value .+ task_data[op.input_keys[2]]
    end
    update_value(task_data, op.output_keys[1], output_value)
end

function _check_shifted_key(input_value::AbstractDict, output_value::AbstractDict, candidates, input_key, input_data, invalid_sources)
    if !issetequal(keys(input_value), keys(output_value))
        return false
    end
    all(_check_shifted_key(value, output_value[key], candidates, input_key, input_data, invalid_sources)
        for (key, value) in input_value)
end

_check_shifted_key(input_value, output_value, candidates, input_key, input_data, invalid_sources) = false

function _check_shifted_key(input_value::Union{Int64,Tuple{Int64,Int64}}, output_value, candidates, input_key, input_data, invalid_sources)
    possible_shift_keys = []
    if !haskey(candidates, input_key)
        for (key, value) in input_data
            if !in(key, invalid_sources) &&
                isa(value, Union{Int64,Tuple{Int64,Int64}}) &&
                    !isnothing(compare_values(input_value .+ value, output_value))
                push!(possible_shift_keys, key)
            end
        end
    else
        for shift_key in candidates[input_key]
            if haskey(input_data, shift_key) && isa(input_data[shift_key], Union{Int64,Tuple{Int64,Int64}}) && !isnothing(compare_values(input_value .+ input_data[shift_key], output_value))
                push!(possible_shift_keys, shift_key)
            end
        end
    end
    candidates[input_key] = possible_shift_keys
    return !isempty(possible_shift_keys)
end

function find_shifted_by_key(taskdata::Vector{Dict{String,Any}}, invalid_sources::AbstractSet{String}, key::String)
    candidates = Dict()
    unmatched = Set(invalid_sources)
    for task_data in taskdata
        if !haskey(task_data, key)
            continue
        end
        for (input_key, value) in task_data
            if in(input_key, unmatched)
                continue
            end

            if !_check_shifted_key(value, task_data[key], candidates, input_key, task_data, invalid_sources)
                push!(unmatched, input_key)
            end
        end
    end
    return reduce(
        vcat,
        [[IncByParam(key, inp_key, shift_key) for shift_key in shift_keys
          if all(haskey(task_data, shift_key) for task_data in taskdata)]
            for (inp_key, shift_keys) in candidates
            if !in(inp_key, unmatched) &&
                all(haskey(task_data, inp_key) for task_data in taskdata)],
        init=[]
    )
end

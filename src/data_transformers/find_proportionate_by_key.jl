using ..PatternMatching:Matcher

struct MultByParam <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    complexity::Float64
    MultByParam(key, inp_key, factor_key) = new([inp_key, factor_key], [key], 1)
end

Base.show(io::IO, op::MultByParam) = print(io, "MultByParam(", op.output_keys[1], ", ", op.input_keys[1], ", ", op.input_keys[2], ")")

Base.:(==)(a::MultByParam, b::MultByParam) = a.output_keys == b.output_keys && a.input_keys == b.input_keys
Base.hash(op::MultByParam, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h)

mult_value(value, factor) = value .* factor
mult_value(value::AbstractVector, factor) = [mult_value(v, factor) for v in value]

function (op::MultByParam)(task_data)
    input_value = task_data[op.input_keys[1]]
    if isa(input_value, Dict)
        output_value = Dict(key => mult_value(value, task_data[op.input_keys[2]]) for (key, value) in input_value)
    else
        output_value = input_value = mult_value(input_value, task_data[op.input_keys[2]])
    end
    update_value(task_data, op.output_keys[1], output_value)
end

function _check_proportions_key(input_value, output_value, possible_factor_keys, task_data, invalid_sources)
    if isempty(possible_factor_keys)
        for (key, value) in task_data
            if !in(key, invalid_sources) &&
                    isa(value, Union{Int64,Tuple{Int64,Int64}}) &&
                    !isnothing(common_value(input_value .* value, output_value))
                push!(possible_factor_keys, key)
            end
        end
    else
        filter!(factor_key -> haskey(task_data, factor_key) && isa(task_data[factor_key], Union{Int64,Tuple{Int64,Int64}}) &&
                              !isnothing(common_value(input_value .* task_data[factor_key], output_value)),
                possible_factor_keys)
    end
    return !isempty(possible_factor_keys)
end


function find_proportionate_by_key(taskdata::Vector{Dict{String,Any}}, invalid_sources::AbstractSet{String}, key::String)
    result = []
    for input_key in keys(taskdata[1])
        if in(input_key, invalid_sources)
            continue
        end
        good = true
        possible_factor_keys = []
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
            if !compare_values(input_value, out_value, possible_factor_keys,
                               (inp_val, out_val, candidates) ->
                                _check_proportions_key(inp_val, out_val, candidates, task_data, invalid_sources),
                               Union{Int64,Tuple{Int64,Int64}})
                good = false
                break
            end
        end
        if good
            append!(result, [MultByParam(key, input_key, factor_key) for factor_key in possible_factor_keys
                             if any(task_data[factor_key] != 1 for task_data in taskdata)])
        end
    end
    return result
end

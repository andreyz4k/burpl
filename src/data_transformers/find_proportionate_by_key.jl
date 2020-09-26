using ..PatternMatching:Matcher

struct MultByParam <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    complexity::Float64
    generability
    MultByParam(key, inp_key, factor_key) = new([inp_key, factor_key], [key], 1, 0)
end

Base.show(io::IO, op::MultByParam) = print(io, "MultByParam(", op.output_keys[1], ", ", op.input_keys[1], ")")

Base.:(==)(a::MultByParam, b::MultByParam) = a.output_keys == b.output_keys && a.input_keys == b.input_keys
Base.hash(op::MultByParam, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h)

(op::MultByParam)(task_data) =
    update_value(task_data, op.output_keys[1], task_data[op.input_keys[1]] .* task_data[op.input_keys[2]])


function _check_proportions_key(input_value::AbstractDict, output_value::AbstractDict, candidates, input_key, task_data, solution)
    if !issetequal(keys(input_value), keys(output_value))
        return false
    end
    all(_check_proportions_key(value, output_value[key], candidates, input_key, task_data, solution)
        for (key, value) in input_value)
end

_check_proportions_key(input_value, output_value, candidates, input_key, task_data, invalid_sources) = false
function _check_proportions_key(input_value::Union{Int64,Tuple{Int64,Int64}}, output_value, candidates, input_key, task_data, invalid_sources)
    possible_factor_keys = []
    if !haskey(candidates, input_key)
        for (key, value) in task_data
            if !in(key, invalid_sources) &&
                    isa(value, Union{Int64,Tuple{Int64,Int64}}) &&
                    !isnothing(compare_values(input_value .* value, output_value))
                push!(possible_factor_keys, key)
            end
        end
    else
        for factor_key in candidates[input_key]
            if haskey(task_data, factor_key) && isa(task_data[factor_key], Union{Int64,Tuple{Int64,Int64}}) &&
                    !isnothing(compare_values(input_value .* task_data[factor_key], output_value))
                push!(possible_factor_keys, factor_key)
            end
        end
    end
    candidates[input_key] = possible_factor_keys
    return !isempty(possible_factor_keys)
end


function find_proportionate_by_key(taskdata::Vector{Dict{String,Any}}, invalid_sources::AbstractSet{String}, key::String)
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

            if !_check_proportions_key(value, task_data[key], candidates, input_key, task_data, invalid_sources)
                push!(unmatched, input_key)
            end
        end
    end
    return reduce(
        vcat,
        [[MultByParam(key, inp_key, factor_key) for factor_key in factor_keys
          if all(haskey(task_data, factor_key) for task_data in taskdata)]
            for (inp_key, factor_keys) in candidates
            if !in(inp_key, unmatched) &&
                all(haskey(task_data, inp_key) for task_data in taskdata)],
        init=[]
    )
end

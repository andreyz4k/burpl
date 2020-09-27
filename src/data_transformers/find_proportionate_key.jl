using ..PatternMatching:Matcher

struct MultParam <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    factor::Int64
    complexity::Float64
    generability
    MultParam(key, inp_key, factor) = new([inp_key], [key, key * "|mult_factor"], factor, 1, 0)
end

Base.show(io::IO, op::MultParam) = print(io, "MultParam(", op.output_keys[1], ", ", op.input_keys[1], ", ", op.factor, ")")

Base.:(==)(a::MultParam, b::MultParam) = a.output_keys == b.output_keys && a.input_keys == b.input_keys && a.factor == b.factor
Base.hash(op::MultParam, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h) + hash(op.factor, h)

function (op::MultParam)(task_data)
    input_value = task_data[op.input_keys[1]]
    if isa(input_value, Dict)
        output_value = Dict(key => value .* op.factor for (key, value) in input_value)
    else
        output_value = input_value .* op.factor
    end
    data = update_value(task_data, op.output_keys[1], output_value)
    update_value(data, op.output_keys[2], op.factor)
end

function _check_proportions(input_value::AbstractDict, output_value::AbstractDict, candidates, input_key)
    if !issetequal(keys(input_value), keys(output_value))
        return false
    end
    all(_check_proportions(inp_value, output_value[key], candidates, input_key) for (key, inp_value) in input_value)
end
FACTORS = [-9, -8, -7, -6, -5, -4, -3, -2, -1, 2, 3, 4, 5, 6, 7, 8, 9]

_check_proportions(input_value, output_value, candidates, input_key) = false

function _check_proportions(input_value::Union{Int64,Tuple{Int64,Int64}}, output_value, candidates, input_key)
    possible_factors = get(candidates, input_key, FACTORS)
    candidates[input_key]  = filter(factor -> !isnothing(compare_values(input_value .* factor, output_value)), possible_factors)
    return !isempty(candidates[input_key])
end

function find_proportionate_key(taskdata::Vector{Dict{String,Any}}, invalid_sources::AbstractSet{String}, key::String)
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

            if !_check_proportions(value, task_data[key], candidates, input_key)
                push!(unmatched, input_key)
            end
        end
    end
    return reduce(
        vcat,
        [[MultParam(key, inp_key, factor) for factor in factors]
            for (inp_key, factors) in candidates
            if !in(inp_key, unmatched) &&
                all(haskey(task_data, inp_key) for task_data in taskdata)],
        init=[]
    )
end

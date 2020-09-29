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

function _check_proportions(input_value::AbstractDict, output_value::AbstractDict, possible_factors)
    if !issetequal(keys(input_value), keys(output_value))
        return false
    end
    all(_check_proportions(inp_value, output_value[key], possible_factors) for (key, inp_value) in input_value)
end
FACTORS = [-9, -8, -7, -6, -5, -4, -3, -2, -1, 2, 3, 4, 5, 6, 7, 8, 9]

_check_proportions(input_value, output_value, possible_factors) = false

_check_proportions(input_value::T, output_value::T, possible_factors) where
    T <: Union{Int64,Tuple{Int64,Int64}} =
    inner_check_proportions(input_value, output_value, possible_factors)
_check_proportions(input_value::T, output_value::Matcher{T}, possible_factors) where
    T <: Union{Int64,Tuple{Int64,Int64}} =
    inner_check_proportions(input_value, output_value, possible_factors)

function inner_check_proportions(input_value, output_value, possible_factors)
    filter!(factor -> !isnothing(compare_values(input_value .* factor, output_value)), possible_factors)
    return !isempty(possible_factors)
end


function find_proportionate_key(taskdata::Vector{Dict{String,Any}}, invalid_sources::AbstractSet{String}, key::String)
    result = []
    for input_key in keys(taskdata[1])
        if in(input_key, invalid_sources)
            continue
        end
        good = true
        possible_factors = copy(FACTORS)
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
            if !_check_proportions(input_value, out_value, possible_factors)
                good = false
                break
            end
        end
        if good
            append!(result, [MultParam(key, input_key, factor) for factor in possible_factors])
        end
    end
    return result
end

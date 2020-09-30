using ..PatternMatching:Matcher

struct CopyParam <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    complexity::Float64
    generability
    CopyParam(key, inp_key) = new([inp_key], [key], 1, 0)
end

Base.show(io::IO, op::CopyParam) = print(io, "CopyParam(", op.output_keys[1], ", ", op.input_keys[1], ")")

Base.:(==)(a::CopyParam, b::CopyParam) = a.output_keys == b.output_keys && a.input_keys == b.input_keys
Base.hash(op::CopyParam, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h)

function (op::CopyParam)(task_data)
    data = update_value(task_data, op.output_keys[1], task_data[op.input_keys[1]])
    data
end

_check_value(input_value, output_value) = false
_check_value(input_value::Matcher, output_value) = false
_check_value(input_value::AbstractDict, output_value::AbstractDict) = _check_value_inner(input_value, output_value)
_check_value(input_value::T, output_value::T) where T = _check_value_inner(input_value, output_value)
_check_value(input_value::T, output_value::Matcher{T}) where T = _check_value_inner(input_value, output_value)

_check_value_inner(input_value, output_value) = !isnothing(compare_values(input_value, output_value))

function find_dependent_key(taskdata::Vector{Dict{String,Any}}, invalid_sources::AbstractSet{String}, key::String)
    result = []
    for input_key in keys(taskdata[1])
        if in(input_key, invalid_sources)
            continue
        end
        good = true
        for task_data in taskdata
            input_value = task_data[input_key]
            out_value = task_data[key]
            if !_check_value(input_value, out_value)
                good = false
                break
            end
        end
        if good
            push!(result, CopyParam(key, input_key))
        end
    end
    return result
end

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

function find_dependent_key(taskdata::Vector{Dict{String,Any}}, invalid_sources::AbstractSet{String}, key::String)
    candidates = Set()
    unmatched = Set(invalid_sources)
    for task_data in taskdata
        if !haskey(task_data, key)
            continue
        end
        for (input_key, value) in task_data
            if in(input_key, unmatched)
                continue
            end
            if !isa(value, Matcher) &&
                    !isnothing(compare_values(value, task_data[key]))
                push!(candidates, input_key)
            else
                push!(unmatched, input_key)
            end
        end
    end
    return [CopyParam(key, inp_key) for inp_key in setdiff(candidates, unmatched)
            if all(haskey(task_data, inp_key) for task_data in taskdata)]
end

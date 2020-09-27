
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
        output_value = Dict(key => value .+ op.shift for (key, value) in input_value)
    else
        output_value = input_value .+ op.shift
    end
    data = update_value(task_data, op.output_keys[1], output_value)
    update_value(data, op.output_keys[2], op.shift)
end

function _check_shifted(input_value::AbstractDict, output_value::AbstractDict, candidates, input_key)
    if !issetequal(keys(input_value), keys(output_value))
        return false
    end
    all(_check_shifted(value, output_value[key], candidates, input_key)
       for (key, value) in input_value)
end

_check_shifted(input_value, output_value, candidates, input_key) = false

_check_shifted(input_value::T, output_value::T, candidates, input_key) where {T <: Union{Int64,Tuple{Int64,Int64}}} =
    _check_shifted_inner(input_value, output_value, candidates, input_key)

_check_shifted(input_value::T, output_value::Matcher{T}, candidates, input_key) where {T <: Union{Int64,Tuple{Int64,Int64}}} =
    _check_shifted_inner(input_value, output_value, candidates, input_key)

function _check_shifted_inner(input_value, output_value, candidates, input_key)
    possible_shifts = []
    if !haskey(candidates, input_key)
        for value in unpack_value(output_value)
            if value != input_value
                push!(possible_shifts, value .- input_value)
            end
        end
    else
        for value in candidates[input_key]
            if !isnothing(compare_values(input_value .+ value, output_value))
                push!(possible_shifts, value)
            end
        end
    end
    candidates[input_key] = possible_shifts
    return !isempty(possible_shifts)
end

function find_shifted_key(taskdata::Vector{Dict{String,Any}}, invalid_sources::AbstractSet{String}, key::String)
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

            if !_check_shifted(value, task_data[key], candidates, input_key)
                push!(unmatched, input_key)
            end
        end
    end
    return reduce(
        vcat,
        [[IncParam(key, inp_key, shift) for shift in shifts]
            for (inp_key, shifts) in candidates
            if !in(inp_key, unmatched) &&
                all(haskey(task_data, inp_key) for task_data in taskdata)],
        init=[]
    )
end

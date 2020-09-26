
using ..Complexity:get_generability,get_complexity

struct MapValues <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    match_pairs::Dict
    complexity::Float64
    generability
    function MapValues(key, inp_key, match_pairs)
        generability = min(get_generability(keys(match_pairs)), 100000000)
        complexity = get_complexity(match_pairs) * generability
        new([inp_key], [key], match_pairs, complexity, generability)
    end
end

Base.show(io::IO, op::MapValues) = print(io, "MapValues(", op.output_keys[1], ", ", op.input_keys[1], ", ", op.match_pairs, ")")

Base.:(==)(a::MapValues, b::MapValues) = a.output_keys == b.output_keys && a.input_keys == b.input_keys && a.match_pairs == b.match_pairs
Base.hash(op::MapValues, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h) + hash(op.match_pairs, h)

function (op::MapValues)(task_data)
    input_value = task_data[op.input_keys[1]]
    if isa(input_value, Dict)
        output_value = Dict(key => op.match_pairs[value] for (key, value) in input_value)
    else
        output_value = op.match_pairs[input_value]
    end
    update_value(task_data, op.output_keys[1], output_value)
end

function compare_mapped_fields(input_value::AbstractDict, output_value::AbstractDict, candidates, input_key)
    if !issetequal(keys(input_value), keys(output_value))
        return false
    end
    all(compare_mapped_fields(value, output_value[key], candidates, input_key)
        for (key, value) in input_value)
end

compare_mapped_fields(input_value, output_value, candidates, input_key) = false

function compare_mapped_fields(input_value::Union{Int64,Tuple}, output_value::Union{Int64,Tuple,Matcher{T}}, candidates, input_key) where {T <: Union{Int64,Tuple}}
    if !haskey(candidates[input_key], input_value)
        candidates[input_key][input_value] = output_value
        return true
    else
        possible_value = compare_values(candidates[input_key][input_value], output_value)
        if !isnothing(possible_value)
            candidates[input_key][input_value] = possible_value
            return true
        end
    end
    return false
end


function unroll_matchers(matching_items)
    if isempty(matching_items)
        return [Dict()]
    end
    (input_val, output_val), rest = Iterators.peel(matching_items)
    tail_values = unroll_matchers(rest)
    results = []
    for tail_value in tail_values
        for value in unpack_value(output_val)
            result = Dict(input_val => value)
            push!(results, merge(Dict(input_val => value), tail_value))
        end
    end
    results
end

using DataStructures:DefaultDict

function find_mapped_key(taskdata::Vector{Dict{String,Any}}, invalid_sources::AbstractSet{String}, key::String)
    candidates = DefaultDict(() -> Dict())
    unmatched = Set(invalid_sources)
    for task_data in taskdata
        if !haskey(task_data, key)
            continue
        end
        for (input_key, value) in task_data
            if in(input_key, unmatched)
                continue
            end

            if !compare_mapped_fields(value, task_data[key], candidates, input_key)
                push!(unmatched, input_key)
            end
        end
    end
    return reduce(
        vcat,
        [[MapValues(key, inp_key, unrolled_matches) for unrolled_matches in unroll_matchers(collect(matching_items))]
            for (inp_key, matching_items) in candidates
            if !in(inp_key, unmatched) &&
                all(haskey(task_data, inp_key) && haskey(matching_items, task_data[inp_key]) for task_data in taskdata)],
        init=[]
    )
end

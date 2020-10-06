
using ..Complexity:get_generability,get_complexity

struct MapValues <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    match_pairs::Dict
    complexity::Float64
    generability
    function MapValues(key, inp_key, match_pairs)
        generability = min(get_generability(keys(match_pairs)), 100000000) + 1
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


function compare_mapped_fields(input_value, output_value, matching_items)
    if !haskey(matching_items, input_value)
        matching_items[input_value] = output_value
        return true
    else
        possible_value = common_value(matching_items[input_value], output_value)
        if !isnothing(possible_value)
            matching_items[input_value] = possible_value
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

_check_existance(matching_items, value::Dict) =
    all(_check_existance(matching_items, val) for val in values(value))
_check_existance(matching_items, value) = haskey(matching_items, value)


function find_mapped_key(taskdata::Vector{Dict{String,Any}}, invalid_sources::AbstractSet{String}, key::String)
    result = []
    for input_key in keys(taskdata[1])
        if in(input_key, invalid_sources)
            continue
        end
        good = true
        matching_items = Dict()
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
            if !compare_values(input_value, out_value, matching_items, compare_mapped_fields, Union{Int64,Tuple}, false)
                good = false
                break
            end
        end
        if good && all(_check_existance(matching_items, task_data[input_key]) for task_data in taskdata)
            append!(result, [MapValues(key, input_key, unrolled_matches) for unrolled_matches in unroll_matchers(collect(matching_items))])
        end
    end
    return result
end

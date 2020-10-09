
using ..Complexity:get_complexity

struct MapValues <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    match_pairs::Dict
    complexity::Float64
    function MapValues(key, inp_key, match_pairs)
        complexity = get_complexity(match_pairs)
        new([inp_key], [key], match_pairs, get_complexity(match_pairs))
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

function unroll_groups(matches)
    if isempty(matches)
        return [[]]
    end
    out = []
    for value in matches[1]
        for tail in unroll_groups(view(matches, 2:length(matches)))
            push!(out, [value, tail...])
        end
    end
    out
end

function check_matching_group(input_value, output_value, candidates)
    options = []
    for (key, value) in input_value
        if compare_values(value, output_value, nothing, _check_value, Any)
            push!(options, key)
        end
    end
    push!(candidates, options)
    return !isempty(options)
end

using ..Abstractors:Abstractor,SelectGroup

function _get_matching_transformers(taskdata::Vector{Dict{String,Any}}, invalid_sources::AbstractSet{String}, key::String)
    result = []
    for input_key in keys(taskdata[1])
        if in(input_key, invalid_sources)
            continue
        end
        good = true
        matching_groups = []
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
            if !compare_values(input_value, out_value, matching_groups, check_matching_group, Any, true, :(AbstractDict{Any,T}))
                good = false
                break
            end
        end
        if good
            for group_keys in unroll_groups(matching_groups)
                key_name = input_key * "|selected_group"
                to_abs = MapValues(key_name, "output", Dict(task_data["output"] => value for (task_data, value) in zip(taskdata, group_keys)))
                from_abs = Abstractor(SelectGroup(), true, [input_key, key_name], [key, key * "|rejected"])
                push!(result, (to_abstract = to_abs, from_abstract = from_abs))
            end
        end
    end
    return result
end


using ..Solutions:Solution,insert_operation

function find_matching_obj_group(key, solution::Solution)
    new_solutions = []
    transformers = _get_matching_transformers(solution.taskdata, union(solution.unfilled_fields, solution.transformed_fields), key)
    for transformer in transformers
        new_solution = insert_operation(solution, transformer.from_abstract, reversed_op=transformer.to_abstract)
        push!(new_solutions, new_solution)
    end
    return new_solutions
end

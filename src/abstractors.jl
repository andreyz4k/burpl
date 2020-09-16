

export Abstractors
module Abstractors

using Memoization

abstract type AbstractorClass end

@memoize abs_keys(p::AbstractorClass) = []
@memoize aux_keys(p::AbstractorClass) = []
@memoize priority(p::AbstractorClass) = 8

@memoize abs_keys(cls::AbstractorClass, key::String) = [key * "|" * a_key for a_key in abs_keys(cls)]
@memoize aux_keys(cls::AbstractorClass, key::String) = [split(key, '|')[1] * "|" * a_key for a_key in aux_keys(cls)]
@memoize detail_keys(cls::AbstractorClass, key::String) = [key]

import ..Operations.Operation

struct Abstractor <: Operation
    cls::AbstractorClass
    to_abstract::Bool
    input_keys::Array{String}
    output_keys::Array{String}
end

function Abstractor(cls::AbstractorClass, key::String, to_abs::Bool)
    if to_abs
        return Abstractor(cls, true, vcat(detail_keys(cls, key), aux_keys(cls, key)), abs_keys(cls, key))
    else
        return Abstractor(cls, false, vcat(abs_keys(cls, key), aux_keys(cls, key)), detail_keys(cls, key))
    end
end

function (p::Abstractor)(_, output_grid, task_data)
    if p.to_abstract
        return output_grid, to_abstract(p, p.cls, task_data)
    else
        return output_grid, from_abstract(p, p.cls, task_data)
    end
end


function to_abstract(p::Abstractor, cls::AbstractorClass, previous_data::Dict)::Dict
    out_data = copy(previous_data)
    input_values = fetch_detailed_value(p, out_data)
    merge!(out_data, wrap_to_abstract_value(p, cls, input_values[1], input_values[2:end]))

    return out_data
end

fetch_detailed_value(p::Abstractor, task_data) =
    [task_data[k] for k in p.input_keys]

using DataStructures:DefaultDict

function wrap_to_abstract_value(p::Abstractor, cls::AbstractorClass, source_value::Dict, aux_values)
    result = DefaultDict(() -> Dict())
    for (key, value) in source_value
        for (out_key, out_value) in wrap_to_abstract_value(p, cls, value, aux_values)
            result[out_key][key] = out_value
        end
    end
    return result
end

# function wrap_to_abstract_value(p::Abstractor, cls::AbstractorClass, source_value::Matcher, aux_values)
#     return source_value.apply_function(partial(self._wrap_to_abstract_value, aux_values=aux_values))
# end

function wrap_to_abstract_value(p::Abstractor, cls::AbstractorClass, source_value, aux_values)
    return to_abstract_value(p, cls, source_value, aux_values)
end


fetch_abs_values(p::Abstractor, cls::AbstractorClass, task_data) =
    [task_data[k] for k in p.input_keys]

function iter_source_values(source_values)
    result = []
    for source_value in source_values
        if isa(source_value, Dict)
            for key in keys(source_value)
                values = [isa(v, Dict) ? v[key] : v for v in source_values]
                push!(result, (key, values))
            end
            return result
        end
    end
    result
end

function from_abstract(p::Abstractor, cls::AbstractorClass, previous_data::Dict)::Dict
    out_data = copy(previous_data)
    source_values = fetch_abs_values(p, cls, out_data)
    if any(isa(v, Dict) for v in source_values)
        result = DefaultDict(() -> Dict())
        for (key, values) in iter_source_values(source_values)
            for (out_key, out_value) in from_abstract_value(p, cls, values)
                result[out_key][key] = out_value
            end
        end
        merge!(out_data, result)
    else
        merge!(out_data, from_abstract_value(p, cls, source_values))
    end

    return out_data
end


function create(cls::AbstractorClass, solution, key)::Array{Tuple{Float64,NamedTuple{(:to_abstract, :from_abstract),Tuple{Abstractor,Abstractor}}},1}
    if any(haskey(solution.observed_data[1], k) for k in abs_keys(cls, key))
        return []
    end
    if !all(haskey(task_data, aux_key) for task_data in solution.observed_data, aux_key in aux_keys(cls, key))
        return []
    end
    data = init_create_check_data(cls, key, solution)

    if !all(check_task_value(
                cls, task_data[key], data,
                get_aux_values_for_task(cls, task_data, key, solution))
            for task_data in solution.observed_data)
        return []
    end
    output = []
    for (priority, abstractor) in create_abstractors(cls, data, key)
        push!(output, (priority * (1.15^(length(split(key, '|')) - 1)), abstractor))
    end
    output
end

init_create_check_data(cls::AbstractorClass, key, solution) = nothing

wrap_check_task_value(cls::AbstractorClass, value, data, aux_values) =
    check_task_value(cls, value, data, aux_values)

wrap_check_task_value(cls::AbstractorClass, value::Dict, data, aux_values) =
    all(wrap_check_task_value(cls, v, data, aux_values) for v in values(value))

# wrap_check_task_value(cls::AbstractorClass, value::Matcher, data, aux_values) =
#     all(wrap_check_task_value(cls, v, data, aux_values) for v in value.get_values())

get_aux_values_for_task(cls::AbstractorClass, task_data, key, solution) =
    [task_data[k] for k in aux_keys(cls, key)]

create_abstractors(cls::AbstractorClass, data, key) =
    [(priority(cls), (to_abstract = Abstractor(cls, key, true), from_abstract = Abstractor(cls, key, false)))]


struct IgnoreBackground <: AbstractorClass end

IgnoreBackground(key, to_abs) = Abstractor(IgnoreBackground(), key, to_abs)
@memoize aux_keys(p::IgnoreBackground) = ["background"]
@memoize priority(p::IgnoreBackground) = 3

function create(cls::IgnoreBackground, solution, key)::Array{Tuple{Float64,NamedTuple{(:to_abstract, :from_abstract),Tuple{Abstractor,Abstractor}}},1}
    if startswith(key, "projected|") || (!in(key, solution.unused_fields) && !in(key, solution.unfilled_fields))
        return []
    end
    invoke(create, Tuple{AbstractorClass,Any,Any}, cls, solution, key)
end

import ..ObjectPrior:Object,get_color

check_task_value(cls::IgnoreBackground, value, data, aux_values) = false
check_task_value(cls::IgnoreBackground, value::Array{Object,1}, data, aux_values) =
    all(get_color(obj) == aux_values[1] for obj in value)

# function get_aux_values_for_task(cls::IgnoreBackground, task_data, key, solution)
#     bgr_key = get_aux_keys_for_key(cls, key)[1]
#     if haskey(task_data, bgr_key) && !in(bgr_key, solution.unfilled_fields)
#         return [task_data[bgr_key]]
#     else
#         return [0]
#     end
# end

to_abstract_value(p::Abstractor, cls::IgnoreBackground, source_value, aux_values) = Dict()
from_abstract_value(p::Abstractor, cls::IgnoreBackground, source_values) = Dict()


struct GroupObjectsByColor <: AbstractorClass end

GroupObjectsByColor(key, to_abs) = Abstractor(GroupObjectsByColor(), key, to_abs)
@memoize abs_keys(p::GroupObjectsByColor) = ["grouped", "group_keys"]

init_create_check_data(cls::GroupObjectsByColor, key, solution) = []

check_task_value(cls::GroupObjectsByColor, value, data, aux_values) = false
function check_task_value(cls::GroupObjectsByColor, value::Array{Object,1}, data, aux_values)
    colors = Set()
    for obj in value
        push!(colors, get_color(obj))
    end
    push!(data, colors)
    return true
end

function create_abstractors(cls::GroupObjectsByColor, data, key)
    if any(length(colors) > 1 for colors in data)
        invoke(create_abstractors, Tuple{AbstractorClass,Any,Any}, cls, data, key)
    end
end

function to_abstract_value(p::Abstractor, cls::GroupObjectsByColor, source_value, aux_values)
    results = DefaultDict(() -> [])
    for obj in source_value
        key = get_color(obj)
        push!(results[key], obj)
    end
    return Dict(
        p.output_keys[1] => results,
        p.output_keys[2] => sort(collect(keys(results)))
    )
end

function from_abstract_value(p::Abstractor, cls::GroupObjectsByColor, source_values)
    data, keys = source_values
    results = reduce(
        vcat,
        (isa(it, Array) ? it : [it] for it in [isa(data, AbstractDict) ? data[key] : data for key in keys]),
        init=Array{Any,1}[]
    )
    return Dict(p.output_keys[1] => results)
end

function from_abstract(p::Abstractor, cls::GroupObjectsByColor, previous_data::Dict)::Dict
    out_data = copy(previous_data)
    source_values = fetch_abs_values(p, cls, out_data)

    merge!(out_data, from_abstract_value(p, cls, source_values))

    return out_data
end

classes = [IgnoreBackground(), GroupObjectsByColor()]
end

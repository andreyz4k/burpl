

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

Base.show(io::IO, p::Abstractor) = print(io,
        string(nameof(typeof(p.cls))),
        "(\"",
        p.to_abstract ? p.input_keys[1] : p.output_keys[1],
        "\", ",
        p.to_abstract,
        ")"
    )

Base.:(==)(a::Abstractor, b::Abstractor) = a.cls == b.cls && a.to_abstract == b.to_abstract && a.input_keys == b.input_keys && a.output_keys == b.output_keys

function to_abstract(p::Abstractor, cls::AbstractorClass, previous_data::Dict)::Dict
    out_data = copy(previous_data)
    input_values = fetch_detailed_value(p, out_data)
    merge!(out_data, wrap_to_abstract_value(p, cls, input_values[1], input_values[2:end]))

    return out_data
end

fetch_detailed_value(p::Abstractor, task_data) =
    [task_data[k] for k in p.input_keys]

using DataStructures:DefaultDict

function wrap_to_abstract_value(p::Abstractor, cls::AbstractorClass, source_value::AbstractDict, aux_values)
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

    if !all(wrap_check_task_value(
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

wrap_check_task_value(cls::AbstractorClass, value::AbstractDict, data, aux_values) =
    all(wrap_check_task_value(cls, v, data, aux_values) for v in values(value))

check_task_value(cls::AbstractorClass, value, data, aux_values) = false

# wrap_check_task_value(cls::AbstractorClass, value::Matcher, data, aux_values) =
#     all(wrap_check_task_value(cls, v, data, aux_values) for v in value.get_values())

get_aux_values_for_task(cls::AbstractorClass, task_data, key, solution) =
    [task_data[k] for k in aux_keys(cls, key)]

create_abstractors(cls::AbstractorClass, data, key) =
    [(priority(cls), (to_abstract = Abstractor(cls, key, true), from_abstract = Abstractor(cls, key, false)))]


include("ignore_background.jl")
include("group_obj_by_color.jl")
include("compact_similar_objects.jl")
include("select_color.jl")
include("sort_array.jl")

using InteractiveUtils:subtypes
classes = [cls() for cls in subtypes(AbstractorClass)]
end

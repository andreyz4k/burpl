export Abstractors
module Abstractors

using Memoization

using ..Operations:Operation,OperationClass

abstract type AbstractorClass <: OperationClass end

@memoize allow_concrete(p::AbstractorClass) = true
@memoize abs_keys(::AbstractorClass) = []
@memoize aux_keys(::AbstractorClass) = []
@memoize priority(::AbstractorClass) = 8

@memoize abs_keys(cls::AbstractorClass, key::String) = [key * "|" * a_key for a_key in abs_keys(cls)]
@memoize detail_keys(::AbstractorClass, key::String) = [key]
function aux_keys(cls::AbstractorClass, key::String, taskdata)::Array{String}
    result = []
    for a_key in aux_keys(cls)
        terms = split(key, '|')
        for i in length(terms) - 1:-1:1
            cand_key = join(terms[1:i], '|') * "|" * a_key
            if haskey(taskdata, cand_key)
                push!(result, cand_key)
                break
            end
        end
    end
    result
end


struct Abstractor <: Operation
    cls::AbstractorClass
    to_abstract::Bool
    input_keys::Array{String}
    output_keys::Array{String}
end

function Abstractor(cls::AbstractorClass, key::String, to_abs::Bool, found_aux_keys::AbstractVector{String}=String[])
    if to_abs
        return Abstractor(cls, true, vcat(detail_keys(cls, key), found_aux_keys), abs_keys(cls, key))
    else
        return Abstractor(cls, false, vcat(abs_keys(cls, key), found_aux_keys), detail_keys(cls, key))
    end
end


function (p::Abstractor)(task_data)
    out_data = copy(task_data)
    input_values = fetch_input_values(p, out_data)
    if p.to_abstract
        func = to_abstract_value
    else
        func = from_abstract_value
    end
    merge!(out_data, wrap_func_call_value_root(p, p.cls, func, input_values...))
    return out_data
end

import ..Operations:needed_input_keys
needed_input_keys(p::Abstractor) = needed_input_keys(p, p.cls)
needed_input_keys(p::Abstractor, ::AbstractorClass) = p.input_keys

Base.show(io::IO, p::Abstractor) = print(io,
        string(nameof(typeof(p.cls))),
        "(\"",
        p.to_abstract ? p.input_keys[1] : p.output_keys[1],
        "\", ",
        p.to_abstract,
        ")"
    )

Base.:(==)(a::Abstractor, b::Abstractor) = a.cls == b.cls && a.to_abstract == b.to_abstract && a.input_keys == b.input_keys && a.output_keys == b.output_keys


fetch_input_values(p::Abstractor, task_data) =
    [in(k, needed_input_keys(p)) ? task_data[k] : get(task_data, k, nothing) for k in p.input_keys]

using DataStructures:DefaultDict

call_wrappers(::AbstractorClass, ::Function) = [
    wrap_func_call_dict_value,
    wrap_func_call_either_value
]

function wrap_func_call_value_root(p::Abstractor, cls::AbstractorClass, func::Function, source_values...)
    wrap_func_call_value(p, cls, func, call_wrappers(cls, func), source_values...)
end

function wrap_func_call_value(p::Abstractor, cls::AbstractorClass, func::Function, wrappers::AbstractVector{Function}, source_values...)
    if isempty(wrappers)
        return func(p, cls, source_values...)
    end
    wrappers[1](p, cls, func, wrappers[2:end], source_values...)
end


wrap_func_call_dict_value(p::Abstractor, cls::AbstractorClass, func::Function, wrappers::AbstractVector{Function}, source_values...) =
    wrap_func_call_value(p, cls, func, wrappers, source_values...)

wrap_func_call_dict_value(p::Abstractor, cls::AbstractorClass, func::Function, wrappers::AbstractVector{Function}, source_value::AbstractDict, aux_values...) =
    wrap_func_call_dict_value_inner(p, cls, func, wrappers, source_value, aux_values...)
wrap_func_call_dict_value(p::Abstractor, cls::AbstractorClass, func::Function, wrappers::AbstractVector{Function}, source_value1::AbstractDict, source_value2::AbstractDict, aux_values...) =
    wrap_func_call_dict_value_inner(p, cls, func, wrappers, source_value1, source_value2, aux_values...)
wrap_func_call_dict_value(p::Abstractor, cls::AbstractorClass, func::Function, wrappers::AbstractVector{Function}, source_value1::AbstractDict, source_value2::AbstractDict, source_value3::AbstractDict) =
    wrap_func_call_dict_value_inner(p, cls, func, wrappers, source_value1, source_value2, source_value3)
wrap_func_call_dict_value(p::Abstractor, cls::AbstractorClass, func::Function, wrappers::AbstractVector{Function}, source_value1, source_value2::AbstractDict, aux_values...) =
    wrap_func_call_dict_value_inner(p, cls, func, wrappers, source_value1, source_value2, aux_values...)
wrap_func_call_dict_value(p::Abstractor, cls::AbstractorClass, func::Function, wrappers::AbstractVector{Function}, source_value1, source_value2::AbstractDict, source_value3::AbstractDict) =
    wrap_func_call_dict_value_inner(p, cls, func, wrappers, source_value1, source_value2, source_value3)
wrap_func_call_dict_value(p::Abstractor, cls::AbstractorClass, func::Function, wrappers::AbstractVector{Function}, source_value1, source_value2, source_value3::AbstractDict) =
    wrap_func_call_dict_value_inner(p, cls, func, wrappers, source_value1, source_value2, source_value3)

function iter_source_values(source_values)
    result = []
    for source_value in source_values
        if isa(source_value, Dict)
            for key in keys(source_value)
                values = [isa(v, Dict) && issetequal(keys(v), keys(source_value)) ? v[key] : v for v in source_values]
                push!(result, (key, values))
            end
            return result
        end
    end
    result
end

function wrap_func_call_dict_value_inner(p::Abstractor, cls::AbstractorClass, func::Function, wrappers::AbstractVector{Function}, source_values...)
    result = DefaultDict(() -> Dict())
    for (key, values) in iter_source_values(source_values)
        for (out_key, out_value) in wrap_func_call_value(p, cls, func, wrappers, values...)
            result[out_key][key] = out_value
        end
    end
    return result
end


using ..PatternMatching:Either,Option

wrap_func_call_either_value(p::Abstractor, cls::AbstractorClass, func::Function, wrappers::AbstractVector{Function}, source_values...) =
    wrap_func_call_value(p, cls, func, wrappers, source_values...)

wrap_func_call_either_value(p::Abstractor, cls::AbstractorClass, func::Function, wrappers::AbstractVector{Function}, source_value::Either, aux_values...) =
    wrap_func_call_either_value_inner(p, cls, func, wrappers, source_value, aux_values...)
wrap_func_call_either_value(p::Abstractor, cls::AbstractorClass, func::Function, wrappers::AbstractVector{Function}, source_value1::Either, source_value2::Either, aux_values...) =
    wrap_func_call_either_value_inner(p, cls, func, wrappers, source_value1, source_value2, aux_values...)
wrap_func_call_either_value(p::Abstractor, cls::AbstractorClass, func::Function, wrappers::AbstractVector{Function}, source_value1::Either, source_value2::Either, source_value3::Either) =
    wrap_func_call_either_value_inner(p, cls, func, wrappers, source_value1, source_value2, source_value3)
wrap_func_call_either_value(p::Abstractor, cls::AbstractorClass, func::Function, wrappers::AbstractVector{Function}, source_value1, source_value2::Either, aux_values...) =
    wrap_func_call_either_value_inner(p, cls, func, wrappers, source_value1, source_value2, aux_values...)
wrap_func_call_either_value(p::Abstractor, cls::AbstractorClass, func::Function, wrappers::AbstractVector{Function}, source_value1, source_value2::Either, source_value3::Either) =
    wrap_func_call_either_value_inner(p, cls, func, wrappers, source_value1, source_value2, source_value3)
wrap_func_call_either_value(p::Abstractor, cls::AbstractorClass, func::Function, wrappers::AbstractVector{Function}, source_value1, source_value2, source_value3::Either) =
    wrap_func_call_either_value_inner(p, cls, func, wrappers, source_value1, source_value2, source_value3)

function wrap_func_call_either_value_inner(p::Abstractor, cls::AbstractorClass, func::Function, wrappers::AbstractVector{Function}, source_values...)
    outputs = DefaultDict(() -> Option[])
    for option in source_values[1].options
        for (key, value) in wrap_func_call_value(p, cls, func, wrappers, option.value, source_values[2:end]...)
            push!(outputs[key], Option(value, option.option_hash))
        end
    end
    return Dict(key => Either(options) for (key, options) in outputs)
end


function create(cls::AbstractorClass, solution, key)::Array{Tuple{Float64,NamedTuple{(:to_abstract, :from_abstract),Tuple{Abstractor,Abstractor}}},1}
    if any(haskey(solution.taskdata[1], k) for k in abs_keys(cls, key))
        return []
    end
    found_aux_keys = [aux_keys(cls, key, task) for task in solution.taskdata]
    if !all(all(length(keys) == length(aux_keys(cls))) && keys == found_aux_keys[1] for keys in found_aux_keys)
        return []
    end
    data = init_create_check_data(cls, key, solution)

    if !all(haskey(task_data, key) && wrap_check_task_value(
                cls, task_data[key], data,
                get_aux_values_for_task(cls, task_data, key, solution))
            for task_data in solution.taskdata)
        return []
    end
    output = []
    for (priority, abstractor) in create_abstractors(cls, data, key, found_aux_keys[1])
        push!(output, (priority * (1.1^(length(split(key, '|')) - 1)), abstractor))
    end
    output
end

init_create_check_data(::AbstractorClass, key, solution) = Dict()

wrap_check_task_value(cls::AbstractorClass, value, data, aux_values) =
    check_task_value(cls, value, data, aux_values)

wrap_check_task_value(cls::AbstractorClass, value::AbstractDict, data, aux_values) =
    all(wrap_check_task_value(cls, v, data, aux_values) for v in values(value))

check_task_value(::AbstractorClass, value, data, aux_values) = false

using ..PatternMatching:Matcher,unpack_value

wrap_check_task_value(cls::AbstractorClass, value::Matcher, data, aux_values) =
    all(wrap_check_task_value(cls, v, data, aux_values) for v in unpack_value(value))

get_aux_values_for_task(cls::AbstractorClass, task_data, key, solution) =
    [task_data[k] for k in aux_keys(cls, key, task_data)]

function create_abstractors(cls::AbstractorClass, data, key, found_aux_keys)
    if haskey(data, "effective") && data["effective"] == false
        return []
    end
    [(priority(cls), (to_abstract = Abstractor(cls, key, true, found_aux_keys),
                      from_abstract = Abstractor(cls, key, false, found_aux_keys)))]
end


include("noop.jl")
include("grid_size.jl")
include("background_color.jl")
include("solid_objects.jl")
include("group_obj_by_color.jl")
# include("compact_similar_objects.jl")
# include("select_color.jl")
include("sort_array.jl")
# include("split_list.jl")
include("transpose.jl")
include("repeat_object_infinite.jl")
include("unwrap_tuple.jl")
include("split_object.jl")
include("unwrap_single_list.jl")
include("remove_redundant_dict.jl")
include("unite_in_rect.jl")
include("unite_touching.jl")
include("count_objects.jl")
include("select_group.jl")

include("compute_functions.jl")

include("dot_product.jl")

all_subtypes(cls) =
    reduce(vcat, ((isabstracttype(c) ? all_subtypes(c) : [c]) for c in subtypes(cls)), init=[])

using InteractiveUtils:subtypes
classes = [cls() for cls in all_subtypes(AbstractorClass) if allow_concrete(cls())]

end

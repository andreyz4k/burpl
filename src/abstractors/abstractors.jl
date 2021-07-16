export Abstractors
module Abstractors


using ..Operations: Operation, OperationClass

abstract type AbstractorClass <: OperationClass end

allow_concrete(p::AbstractorClass) = true
abs_keys(::AbstractorClass) = []
aux_keys(::AbstractorClass) = []
priority(::AbstractorClass) = 8

abs_keys(cls::AbstractorClass, key::String) = String[key * "|" * a_key for a_key in abs_keys(cls)]
detail_keys(::AbstractorClass, key::String) = [key]
function aux_keys(cls::AbstractorClass, key::String, taskdata)::Array{String}
    result = []
    for a_key in aux_keys(cls)
        terms = split(key, '|')
        for i = length(terms)-1:-1:1
            cand_key = join(terms[1:i], '|') * "|" * a_key
            if haskey(taskdata, cand_key)
                push!(result, cand_key)
                break
            end
        end
    end
    result
end


struct Abstractor{T<:AbstractorClass} <: Operation
    cls::T
    to_abstract::Bool
    from_output::Bool
    input_keys::Vector{String}
    output_keys::Vector{String}
    aux_keys::Vector{String}
end

function Abstractor(
    cls::AbstractorClass,
    key::String,
    to_abs::Bool,
    from_output::Bool,
    found_aux_keys::AbstractVector{String} = String[],
)
    if to_abs
        return Abstractor(
            cls,
            true,
            from_output,
            vcat(detail_keys(cls, key), found_aux_keys),
            abs_keys(cls, key),
            found_aux_keys,
        )
    else
        return Abstractor(
            cls,
            false,
            from_output,
            vcat(abs_keys(cls, key), found_aux_keys),
            detail_keys(cls, key),
            found_aux_keys,
        )
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
    merge!(out_data, wrap_func_call_value_root(p, func, input_values...))
    return out_data
end

import ..Operations: needed_input_keys
needed_input_keys(p::Abstractor) = p.input_keys

Base.show(io::IO, p::Abstractor) = print(
    io,
    string(nameof(typeof(p.cls))),
    "(",
    (vcat((["\"", k, "\", "] for k in (p.to_abstract ? p.input_keys : p.output_keys))...))...,
    p.to_abstract,
    ")",
)

Base.:(==)(a::Abstractor, b::Abstractor) =
    a.cls == b.cls && a.to_abstract == b.to_abstract && a.input_keys == b.input_keys && a.output_keys == b.output_keys


fetch_input_values(p::Abstractor, task_data) =
    [in(k, needed_input_keys(p)) ? task_data[k] : get(task_data, k, nothing) for k in p.input_keys]

using DataStructures: DefaultDict

call_wrappers() =
    [wrap_func_call_dict_value, wrap_func_call_either_value, wrap_func_call_shape_value, wrap_func_call_obj_group_value]

function wrap_func_call_value_root(p::Abstractor, func::Function, source_values...)
    wrap_func_call_value(p, func, call_wrappers(), source_values...)
end

function wrap_func_call_value(p::Abstractor, func::Function, wrappers::AbstractVector{Function}, source_values...)
    if isempty(wrappers)
        return func(p, source_values...)
    end
    wrappers[1](p, func, wrappers[2:end], source_values...)
end

function iter_source_values(source_values)
    result = []
    for source_value in source_values
        if isa(source_value, Dict)
            for key in keys(source_value)
                vals = [isa(v, Dict) && issetequal(keys(v), keys(source_value)) ? v[key] : v for v in source_values]
                push!(result, (key, vals))
            end
            return result
        end
    end
    result
end

function wrap_func_call_dict_value(p::Abstractor, func::Function, wrappers::AbstractVector{Function}, source_values...)
    if any(isa(v, AbstractDict) for v in source_values)
        result = DefaultDict(() -> Dict())
        for (key, vals) in iter_source_values(source_values)
            for (out_key, out_value) in wrap_func_call_value_root(p, func, vals...)
                result[out_key][key] = out_value
            end
        end
        return result
    end
    wrap_func_call_value(p, func, wrappers, source_values...)
end


using ..PatternMatching: Either, Option

_all_hashes(source_values) = reduce(
    vcat,
    [isa(v, Either) ? [o.option_hash for o in v.options if !isnothing(o.option_hash)] : [] for v in source_values],
    init = [],
)

_all_options(item) = [(item, [])]
function _all_options(item::Either)
    result = []
    for option in item.options
        for (value, hashes) in _all_options(option.value)
            if isnothing(option.option_hash)
                push!(result, (value, hashes))
            else
                push!(result, (value, [option.option_hash, hashes...]))
            end
        end
    end
    result
end


function iter_source_either_values(source_values)
    if isempty(source_values)
        return [([], [], Set([]))]
    end
    if !isa(source_values[1], Either)
        return [
            ([source_values[1], tail[1]...], tail[2], tail[3]) for
            tail in iter_source_either_values(source_values[2:end])
        ]
    end
    result = []
    for tail_res in iter_source_either_values(source_values[2:end])
        all_options = _all_options(source_values[1])
        all_hashes = reduce(union, [t[2] for t in all_options], init = Set())
        for (value, hashes) in all_options
            if isempty(hashes)
                push!(result, ([value, tail_res[1]...], tail_res[2], tail_res[3]))
                continue
            elseif any(in(h, tail_res[3]) && !in(h, tail_res[2]) for h in hashes)
                continue
            end
            push!(
                result,
                (
                    [value, tail_res[1]...],
                    [filter(h -> !in(h, tail_res[2]), hashes)..., tail_res[2]...],
                    union(all_hashes, tail_res[3]),
                ),
            )
        end
    end
    result
end

function push_to_tree!(tree::Dict, keys, value)
    if length(keys) == 1
        if !haskey(tree, keys[1])
            tree[keys[1]] = [value]
        else
            push!(tree[keys[1]], value)
        end
    else
        if !haskey(tree, keys[1])
            tree[keys[1]] = Dict()
        end
        push_to_tree!(tree[keys[1]], keys[2:end], value)
    end
end

unfold_options(options::AbstractVector) = Either(options)

unfold_options(options::Dict) = Either([Option(unfold_options(vals), option_hash) for (option_hash, vals) in options])

function wrap_func_call_either_value(
    p::Abstractor,
    func::Function,
    wrappers::AbstractVector{Function},
    source_values...,
)
    if any(isa(v, Either) for v in source_values)
        outputs = Dict()
        for (vals, hashes, _) in iter_source_either_values(source_values)
            for (key, value) in wrap_func_call_value_root(p, func, vals...)
                push_to_tree!(outputs, [key, hashes...], value)
            end
        end
        return Dict(key => unfold_options(options) for (key, options) in outputs)
    end
    wrap_func_call_value(p, func, wrappers, source_values...)
end


using ..PatternMatching: ObjectShape, ObjectsGroup, Matcher
using ..ObjectPrior: Object

_propagate_object_shape(value::Any) = value
_propagate_object_shape(value::Object) = ObjectShape(value)
_propagate_object_shape(value::Matcher{Object}) = throw("Incorrect value " * value)
_propagate_object_shape(value::ObjectShape) = throw("Double shape " * value)
_propagate_object_shape(value::Set{Object}) = ObjectsGroup(value)
_propagate_object_shape(value::Matcher{Set{Object}}) = ObjectsGroup(value)
_propagate_object_shape(::ObjectsGroup) = throw("Double shape" * value)
_propagate_object_shape(value::Either) =
    Either([Option(_propagate_object_shape(option.value), option.option_hash) for option in value.options])

function wrap_func_call_shape_value(p::Abstractor, func::Function, wrappers::AbstractVector{Function}, source_values...)
    if any(isa(v, ObjectShape) || isa(v, AbstractVector{ObjectShape}) for v in source_values)
        outputs = Dict()
        unwrapped_values = [
            isa(v, ObjectShape) ? v.object : isa(v, AbstractVector{ObjectShape}) ? [i.object for i in v] : v for
            v in source_values
        ]
        for (key, value) in wrap_func_call_value_root(p, func, unwrapped_values...)
            outputs[key] = _propagate_object_shape(value)
        end
        return outputs
    end
    wrap_func_call_value(p, func, wrappers, source_values...)
end


function wrap_func_call_obj_group_value(
    p::Abstractor,
    func::Function,
    wrappers::AbstractVector{Function},
    source_values...,
)
    if any(isa(v, ObjectsGroup) for v in source_values)
        outputs = Dict()
        unwrapped_values = [isa(v, ObjectsGroup) ? v.objects : v for v in source_values]
        for (key, value) in wrap_func_call_value_root(p, func, unwrapped_values...)
            outputs[key] = _propagate_object_shape(value)
        end
        return outputs
    end
    wrap_func_call_value(p, func, wrappers, source_values...)
end


function create(
    cls::AbstractorClass,
    solution,
    key,
)::Array{Tuple{Float64,NamedTuple{(:to_abstract, :from_abstract),Tuple{Abstractor,Abstractor}}},1}
    if any(haskey(solution.taskdata[1], k) for k in abs_keys(cls, key))
        return []
    end
    found_aux_keys = [aux_keys(cls, key, task) for task in solution.taskdata]
    if !all(all(length(keys) == length(aux_keys(cls))) && keys == found_aux_keys[1] for keys in found_aux_keys)
        return []
    end
    data = init_create_check_data(cls, key, solution)

    if !all(
        haskey(task_data, key) &&
        wrap_check_task_value(cls, task_data[key], data, get_aux_values_for_task(cls, task_data, key, solution)) for
        task_data in solution.taskdata
    )
        return []
    end
    output = []
    from_output = in(key, solution.unfilled_fields)
    for (priority, abstractor) in create_abstractors(cls, from_output, data, key, found_aux_keys[1])
        push!(output, (priority * (1.1^(length(split(key, '|')) - 1)), abstractor))
    end
    output
end

init_create_check_data(::AbstractorClass, key, solution) = Dict()

wrap_check_task_value(cls::AbstractorClass, value, data, aux_values) = check_task_value(cls, value, data, aux_values)

wrap_check_task_value(cls::AbstractorClass, value::AbstractDict, data, aux_values) =
    all(wrap_check_task_value(cls, v, data, aux_values) for v in values(value))

check_task_value(::AbstractorClass, value, data, aux_values) = false

using ..PatternMatching: Matcher, unwrap_matcher

wrap_check_task_value(cls::AbstractorClass, value::Matcher, data, aux_values) =
    all(wrap_check_task_value(cls, v, data, aux_values) for v in unwrap_matcher(value))

using ..PatternMatching: SubSet
wrap_check_task_value(cls::AbstractorClass, value::SubSet, data, aux_values) = false

get_aux_values_for_task(cls::AbstractorClass, task_data, key, solution) =
    [task_data[k] for k in aux_keys(cls, key, task_data)]

function create_abstractors(cls::AbstractorClass, from_output, data, key, found_aux_keys)
    if haskey(data, "effective") && data["effective"] == false
        return []
    end
    [(
        priority(cls),
        (
            to_abstract = Abstractor(cls, key, true, from_output, found_aux_keys),
            from_abstract = Abstractor(cls, key, false, from_output, found_aux_keys),
        ),
    )]
end


include("noop.jl")
# include("grid_size.jl")
include("background_color.jl")
include("solid_objects.jl")
include("group_obj_by_color.jl")
include("compact_similar_objects.jl")
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
include("get_position.jl")
include("separate_axis.jl")
include("symmetry.jl")

include("compute_functions.jl")

include("dot_product.jl")

all_subtypes(cls) = reduce(vcat, ((isabstracttype(c) ? all_subtypes(c) : [c]) for c in subtypes(cls)), init = [])

using InteractiveUtils: subtypes
classes = [cls() for cls in all_subtypes(AbstractorClass) if allow_concrete(cls())]

end

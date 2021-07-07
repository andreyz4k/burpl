

struct SelectGroup <: AbstractorClass end

abs_keys(::SelectGroup) = ["selected_by", "rejected_by"]
priority(::SelectGroup) = 4

abs_keys(cls::SelectGroup, key::String, param_key::String) =
    [key * "|" * a_key * "|" * param_key for a_key in abs_keys(cls)]
detail_keys(::SelectGroup, key::String, param_key::String) = [key, param_key]


SelectGroup(key, selector_key, to_abs) = Abstractor(SelectGroup(), key, selector_key, to_abs)

function Abstractor(cls::SelectGroup, key::String, selector_key::String, to_abs::Bool)
    if to_abs
        return Abstractor(cls, true, detail_keys(cls, key, selector_key), abs_keys(cls, key, selector_key), String[])
    else
        return Abstractor(
            cls,
            false,
            vcat(abs_keys(cls, key, selector_key), detail_keys(cls, key, selector_key)[2:2]),
            detail_keys(cls, key, selector_key)[1:1],
            String[],
        )
    end
end

function create(
    cls::SelectGroup,
    solution,
    key,
)::Array{Tuple{Float64,NamedTuple{(:to_abstract, :from_abstract),Tuple{Abstractor,Abstractor}}},1}
    return []
    data = init_create_check_data(cls, key, solution)

    if !all(!ismissing(val) && check_task_value(cls, val, data, []) for val in solution.taskdata[key])
        return []
    end
    output = []
    for (priority, abstractor) in create_abstractors(cls, data, key)
        push!(output, (priority * (1.15^(length(split(key, '|')) - 1)), abstractor))
    end
    output
end


function init_create_check_data(::SelectGroup, key, solution)
    data = Dict("effective" => false, "allowed_choices" => Set{String}())
    existing_choices = Set{String}()
    matcher = Regex("$(replace(key, '|' => "\\|"))\\|selected_by\\|(.*)")
    for k in keys(solution.taskdata)
        m = match(matcher, k)
        if !isnothing(m) && haskey(solution.taskdata, m.captures[1])
            push!(existing_choices, m.captures[1])
        end
    end
    for k in keys(solution.taskdata)
        if k != key &&
           in(key, solution.field_info[k].previous_fields) &&
           !in(k, existing_choices) &&
           all(
               isa(dict_value, AbstractDict) && haskey(dict_value, candidate_key) for
               (dict_value, candidate_key) in zip(solution.taskdata[key], solution.taskdata[k])
           )
            push!(data["allowed_choices"], k)
        end
    end
    data
end

function check_task_value(::SelectGroup, value::AbstractDict, data, aux_values)
    data["effective"] |= length(value) > 1
    return true
end

function create_abstractors(cls::SelectGroup, data, key)
    if data["effective"]
        [
            (
                priority(cls),
                (
                    to_abstract = Abstractor(cls, key, selector_key, true),
                    from_abstract = Abstractor(cls, key, selector_key, false),
                ),
            ) for selector_key in data["allowed_choices"]
        ]
    else
        []
    end
end

function wrap_func_call_dict_value(
    p::Abstractor{SelectGroup},
    func::Function,
    wrappers::AbstractVector{Function},
    source_values...,
)
    wrap_func_call_value(p, func, wrappers, source_values...)
end

using ..PatternMatching: update_value
using ..Taskdata: TaskData

function to_abstract_value(p::Abstractor{SelectGroup}, source_value::AbstractDict, selected_key)
    rejected = copy(source_value)
    delete!(rejected, selected_key)
    out = update_value(
        TaskData(Dict{String,Any}(), Dict{String,Any}(), Set()),
        p.output_keys[1],
        [source_value[selected_key]],
    )
    out = update_value(out, p.output_keys[2], [rejected])
    Dict(p.output_keys[1] => out[p.output_keys[1]][1], p.output_keys[2] => out[p.output_keys[2]][1])
end

function from_abstract_value(p::Abstractor{SelectGroup}, selected, rejected, selector_key)
    out = copy(rejected)
    out[selector_key] = selected
    Dict(p.output_keys[1] => out)
end

import ..Solutions: get_source_key

function get_source_key(operation::Abstractor{SelectGroup}, source_key)
    operation.input_keys[1]
end

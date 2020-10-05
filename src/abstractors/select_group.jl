

struct SelectGroup <: AbstractorClass end

@memoize abs_keys(::SelectGroup) = ["selected_by", "rejected_by"]
@memoize priority(::SelectGroup) = 2

@memoize abs_keys(cls::SelectGroup, key::String, param_key::String) = [key * "|" * a_key * "|" * param_key for a_key in abs_keys(cls)]
@memoize aux_keys(::SelectGroup, key::String, param_key::String) = [param_key]


SelectGroup(key, selector_key, to_abs) = Abstractor(SelectGroup(), key, selector_key, to_abs)

function Abstractor(cls::SelectGroup, key::String, selector_key::String, to_abs::Bool)
    if to_abs
        return Abstractor(cls, true, vcat(detail_keys(cls, key), aux_keys(cls, key, selector_key)), abs_keys(cls, key, selector_key))
    else
        return Abstractor(cls, false, vcat(abs_keys(cls, key, selector_key), aux_keys(cls, key, selector_key)), detail_keys(cls, key))
    end
end

function create(cls::SelectGroup, solution, key)::Array{Tuple{Float64,NamedTuple{(:to_abstract, :from_abstract),Tuple{Abstractor,Abstractor}}},1}
    data = init_create_check_data(cls, key, solution)

    if !all(haskey(task_data, key) && check_task_value(
                cls, task_data[key], data,
                task_data)
            for task_data in solution.taskdata)
        return []
    end
    output = []
    for (priority, abstractor) in create_abstractors(cls, data, key)
        push!(output, (priority * (1.15^(length(split(key, '|')) - 1)), abstractor))
    end
    output
end


function init_create_check_data(::SelectGroup, key, solution)
    data = Dict(
        "existing_choices" => Set{String}(),
        "key" => key,
        "effective" => false,
    )
    matcher = Regex("$(replace(key, '|' => "\\|"))\\|selected_by\\|(.*)")
    sample_task = solution.taskdata[1]
    for k in keys(sample_task)
        m = match(matcher, k)
        if !isnothing(m) && haskey(sample_task, m.captures[1])
            push!(data["existing_choices"], m.captures[1])
        end
    end
    data
end

function check_task_value(::SelectGroup, value::AbstractDict, data, task_data)
    data["effective"] |= length(value) > 1
    if !haskey(data, "allowed_choices")
        data["allowed_choices"] = Set{String}()
        for (key, data_value) in task_data
            if key != data["key"] && startswith(key, data["key"]) &&
                    !in(key, data["existing_choices"]) && haskey(value, data_value)
                push!(data["allowed_choices"], key)
            end
        end
    else
        filter!(key -> haskey(value, task_data[key]), data["allowed_choices"])
    end
    return !isempty(data["allowed_choices"])
end

function create_abstractors(cls::SelectGroup, data, key)
    if data["effective"]
        [(priority(cls),
          (to_abstract = Abstractor(cls, key, selector_key, true),
           from_abstract = Abstractor(cls, key, selector_key, false)))
         for selector_key in data["allowed_choices"]]
    else
        []
    end
end

function wrap_func_call_dict_value(p::Abstractor, cls::SelectGroup, func::Function, wrappers::AbstractVector{Function}, source_values...)
    wrap_func_call_value(p, cls, func, wrappers, source_values...)
end

function to_abstract_value(p::Abstractor, ::SelectGroup, source_value::AbstractDict, selected_key)
    rejected = copy(source_value)
    delete!(rejected, selected_key)
    Dict(
        p.output_keys[1] => source_value[selected_key],
        p.output_keys[2] => rejected
    )
end

function from_abstract_value(p::Abstractor, ::SelectGroup, selected, rejected, selector_key)
    out = copy(rejected)
    out[selector_key] = selected
    Dict(p.output_keys[1] => out)
end

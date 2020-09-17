
struct SelectColor <: AbstractorClass end

@memoize priority(p::SelectColor) = 2

@memoize abs_keys(p::SelectColor) = ["selected_by_color", "rejected_by_color"]
@memoize aux_keys(p::AbstractorClass) = []
@memoize priority(p::AbstractorClass) = 8

@memoize abs_keys(cls::AbstractorClass, key::String, param_key::String) = [key * "|" * a_key * "|" * param_key for a_key in abs_keys(cls)]
@memoize aux_keys(cls::AbstractorClass, key::String, param_key::String) = [param_key]
@memoize detail_keys(cls::AbstractorClass, key::String) = [key]


SelectColor(key, selector_key, to_abs) = Abstractor(SelectColor(), key, selector_key, to_abs)

function Abstractor(cls::SelectColor, key::String, selector_key::String, to_abs::Bool)
    if to_abs
        return Abstractor(cls, true, vcat(detail_keys(cls, key), aux_keys(cls, key, selector_key)), abs_keys(cls, key, selector_key))
    else
        return Abstractor(cls, false, abs_keys(cls, key, selector_key), detail_keys(cls, key))
    end
end


function init_create_check_data(p::SelectColor, key, solution)
    data = Dict(
        "existing_choices" => Set{String}(),
        "interesting_choices" => Set{String}(),
        "prefix" => split(key, '|')[1],
    )
    matcher = Regex("$key\\|selected_by_color\\|(.*)")
    sample_task = solution.observed_data[1]
    for k in keys(sample_task)
        m = match(matcher, k)
        if !isnothing(m) && haskey(sample_task, m.captures[1])
            push!(data["existing_choices"], m.captures[1])
        end
    end
    data
end

PREFIX_VALUES = Dict(
    "input" => 0,
    "projected" => 1,
    "output" => 2
)


function check_task_value(cls::SelectColor, value::AbstractVector{Object}, data, task_data)
    index_values = DefaultDict(() -> Set())
    for obj in value
        if !haskey(data, "allowed_choices")
            data["allowed_choices"] = Set{String}()
            for (key, data_value) in task_data
                key_prefix = split(key, '|')[1]
                if PREFIX_VALUES[key_prefix] > PREFIX_VALUES[data["prefix"]]
                    continue
                end
                if !in(key, data["existing_choices"]) && isa(data_value, Int)
                    push!(data["allowed_choices"], key)
                end
            end
            if isempty(data["allowed_choices"])
                return false
            end
        end
        for key in data["allowed_choices"]
            value = get_color(obj)
            push!(index_values[key], value == task_data[key])
        end
    end
    for (key, values) in index_values
        if !in(true, values)
            delete!(data["allowed_choices"], key)
            if in(key, data["interesting_choices"])
                delete!(data["interesting_choices"], key)
            end
        end
        if in(key, data["allowed_choices"]) && length(values) > 1
            push!(data["interesting_choices"], key)
        end
    end
    true
end

create_abstractors(cls::SelectColor, data, key) =
    [(priority(cls),
        (to_abstract = Abstractor(cls, key, selector_key, true),
            from_abstract = Abstractor(cls, key, selector_key, false)))
            for selector_key in data["interesting_choices"]]

function create(cls::SelectColor, solution, key)::Array{Tuple{Float64,NamedTuple{(:to_abstract, :from_abstract),Tuple{Abstractor,Abstractor}}},1}
    data = init_create_check_data(cls, key, solution)

    if !all(check_task_value(
                cls, task_data[key], data,
                task_data)
            for task_data in solution.observed_data)
        return []
    end
    output = []
    for (priority, abstractor) in create_abstractors(cls, data, key)
        push!(output, (priority * (1.15^(length(split(key, '|')) - 1)), abstractor))
    end
    output
end


to_abstract_value(p::Abstractor, cls::SelectColor, source_value::AbstractVector{Object}, aux_values) =
    Dict(
        p.output_keys[1] => filter(obj -> get_color(obj) == aux_values[1], source_value),
        p.output_keys[2] => filter(obj -> get_color(obj) != aux_values[1], source_value),
    )

from_abstract_value(p::Abstractor, cls::SelectColor, source_values) =
    Dict(
        p.output_keys[1] => vcat(source_values...)
    )



struct DotProductClass <: AbstractorClass end

const ALLOWED_DOT_PRODUCTS = [
    [SplitObject(),RepeatObjectInfinite()]
]

struct DotProduct <: Operation
    abstractors::Array{Abstractor}
    input_keys::Array{String}
    output_keys::Array{String}
    needed_input_keys::Array{String}
    aux_keys::Array{String}
    DotProduct(abstractors) = new(abstractors, _get_keys_for_items(abstractors)...)
end


function (p::DotProduct)(task_data)
    inner_keys = []
    for abstractor in p.abstractors[1:end - 1]
        task_data = abstractor(task_data)
        append!(inner_keys, abstractor.output_keys)
    end
    task_data = p.abstractors[end](task_data)
    for key in inner_keys
        delete!(task_data, key)
    end
    task_data
end

needed_input_keys(p::DotProduct) = p.needed_input_keys

Base.show(io::IO, p::DotProduct) = print(io,
    "DotProduct(",
    p.abstractors,
    ")"
)

Base.:(==)(a::DotProduct, b::DotProduct) = a.abstractors == b.abstractors && a.input_keys == b.input_keys && a.output_keys == b.output_keys

using ..Solutions:insert_operation

function get_abstractor_options(abs_classes, solution, key, to_abs)
    if isempty(abs_classes)
        return [[]]
    end
    available_abstractors = create(abs_classes[1], solution, key)
    res = []
    for (priority, abstractor) in available_abstractors
        if to_abs
            new_solution = insert_operation(solution, abstractor.to_abstract)
        else
            new_solution = insert_operation(solution, abstractor.from_abstract, reversed_op=abstractor.to_abstract)
        end
        for new_key in abstractor.to_abstract.output_keys
            for abs_options in get_abstractor_options(abs_classes[2:end], new_solution, new_key, to_abs)
                if length(abs_options) == length(abs_classes) - 1
                    push!(res, vcat([(priority, abstractor)], abs_options))
                end
            end
        end
    end
    res
end

function _get_keys_for_items(items)
    input_keys = []
    needed_inp_keys = []
    output_keys = []
    aux_keys = []
    for item in items
        new_inp_keys = filter(k -> !in(k, output_keys), item.input_keys)
        append!(input_keys, new_inp_keys)
        append!(aux_keys, filter(k -> !in(k, output_keys), item.aux_keys))
        append!(needed_inp_keys, filter(k -> in(k, needed_input_keys(item)), new_inp_keys))
        filter!(k -> !in(k, item.input_keys), output_keys)
        append!(output_keys, item.output_keys)
    end
    input_keys, output_keys, needed_inp_keys, aux_keys
end

using Statistics:mean
function create(::DotProductClass, solution, key)::Array{Tuple{Float64,NamedTuple{(:to_abstract, :from_abstract),Tuple{DotProduct,DotProduct}}},1}
    res = []
    for abstractor_classes in ALLOWED_DOT_PRODUCTS
        abstractor_paths = get_abstractor_options(abstractor_classes, solution, key, !in(key, solution.unfilled_fields))
        for path in abstractor_paths
            push!(res, (mean(p[1] for p in path),
                        (to_abstract = DotProduct(
                            [p[2].to_abstract for p in path],
                         ),
                         from_abstract = DotProduct(
                            [p[2].from_abstract for p in path[end:-1:1]],
                         ))))
        end
    end
    res
end

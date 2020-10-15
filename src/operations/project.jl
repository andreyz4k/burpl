

struct Project <: Operation
    operations
    input_keys
    aux_keys
    output_keys
    Project(operations, out_keys) =
        new(copy(operations), _get_keys_for_items(operations)..., ["projected|" * key for key in out_keys])
end

Base.show(io::IO, p::Project) = print(io, "Project(", (vcat(([op,", "] for op in p.operations)...))..., ")")

Base.:(==)(a::Project, b::Project) = a.operations == b.operations

function _get_keys_for_items(items)
    input_keys = []
    output_keys = []
    aux_keys = []
    for item in items
        new_inp_keys = filter(k -> !in(k, output_keys), item.input_keys)
        append!(input_keys, new_inp_keys)
        append!(aux_keys, filter(k -> !in(k, output_keys), item.aux_keys))
        append!(output_keys, item.output_keys)
    end
    input_keys, aux_keys
end

function (p::Project)(observed_data)
    processed_data = observed_data
    for operation in p.operations
        if all(haskey(processed_data, key) for key in needed_input_keys(operation))
            processed_data = operation(processed_data)
        end
    end
    out_data = filter(keyval -> !startswith(keyval[1], "projected|"), observed_data)
    for key in p.output_keys
        stripped_key = replace(key, "projected|" => "")
        if haskey(processed_data, stripped_key)
            out_data[key] = processed_data[stripped_key]
        end
    end

    return out_data
end

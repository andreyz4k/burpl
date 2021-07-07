

struct Project <: Operation
    operations::Any
    input_keys::Any
    output_keys::Any
    aux_keys::Any
    Project(operations, out_keys) = new(copy(operations), _get_keys_for_items(operations, out_keys)...)
end

Base.show(io::IO, p::Project) = print(io, "Project(", (vcat(([op, ", "] for op in p.operations)...))..., ")")

Base.:(==)(a::Project, b::Project) = a.operations == b.operations

function _get_keys_for_items(items, out_keys)
    input_keys = []
    output_keys = Set()
    aux_keys = []
    for item in items
        new_inp_keys = filter(k -> !in(k, output_keys), item.input_keys)
        append!(input_keys, new_inp_keys)
        if hasproperty(item, :aux_keys)
            append!(aux_keys, filter(k -> !in(k, output_keys), item.aux_keys))
        end
        union!(output_keys, item.output_keys)
    end
    input_keys, ["projected|" * key for key in output_keys if in(key, out_keys)], aux_keys
end

function (p::Project)(observed_data)
    processed_data = observed_data
    for operation in p.operations
        if !isa(operation, WrapMatcher) && all(haskey(processed_data, key) for key in needed_input_keys(operation))
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

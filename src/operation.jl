export Operations
module Operations

export Operation
export Project

abstract type Operation end

get_sorting_keys(operation::Operation) = operation.output_keys

struct Project <: Operation
    operations
    input_keys
    output_keys
    Project(operations, out_keys) =
        new(copy(operations), [], ["projected|" * key for key in out_keys])
end

Base.show(io::IO, p::Project) = print(io, "Project(", (vcat(([op,", "] for op in p.operations)...))..., ")")

Base.:(==)(a::Project, b::Project) = a.operations == b.operations

function (p::Project)(input_grid, output_grid, observed_data)
    processed_data = observed_data
    for operation in p.operations
        if all(haskey(processed_data, key) for key in operation.input_keys)
            output_grid, processed_data = operation(input_grid, output_grid, processed_data)
        end
    end
    out_data = filter(keyval -> !startswith(keyval[1], "projected|"), observed_data)
    for key in p.output_keys
        stripped_key = replace(key, "projected|" => "")
        if haskey(processed_data, stripped_key)
            out_data[key] = processed_data[stripped_key]
        end
    end

    return output_grid, out_data
end
end

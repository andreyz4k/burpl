using ..Operations: Operation

mutable struct Block
    operations::Vector{Operation}
    hash_value::Union{UInt64,Nothing}
    Block(operations) = new(operations, nothing)
end

Block() = Block([])

function insert_operation(blocks::AbstractVector{Block}, operation::Operation)::Tuple{Block,Int}
    filled_keys =
        reduce(union, [op.output_keys for block in blocks[1:end-1] for op in block.operations], init = Set(["input"]))
    last_block_outputs = reduce(
        merge,
        [Dict(key => index for key in op.output_keys) for (index, op) in enumerate(blocks[end].operations)],
        init = Dict(),
    )
    # last_block_outputs = reduce(union, [op.output_keys for op in blocks[end].operations], init=Set{String}())
    needed_fields = setdiff(operation.input_keys, filled_keys)
    union!(needed_fields, filter(k -> haskey(last_block_outputs, k), operation.output_keys))
    operations = copy(blocks[end].operations)
    for (index, op) in enumerate(operations)
        if isempty(needed_fields) || any(in(key, op.input_keys) for key in operation.output_keys)
            insert!(operations, index, operation)
            return Block(operations), index
        end
        setdiff!(needed_fields, filter(key -> last_block_outputs[key] == index, op.output_keys))
    end
    push!(operations, operation)
    Block(operations), length(operations)
end

Base.show(io::IO, b::Block) = print(io, "Block([\n", (vcat((["\t\t", op, ",\n"] for op in b.operations)...))..., "\t])")

using ..Taskdata: TaskData, persist_data

function (block::Block)(observed_data::TaskData)::TaskData
    for op in block.operations
        try
            observed_data = op(observed_data)
        catch e
            if isa(e, KeyError)
                @info("missing key $e")
            else
                rethrow()
            end
        end
    end
    observed_data
end

Base.:(==)(a::Block, b::Block) = a.operations == b.operations

function Base.hash(b::Block, h::UInt64)
    if isnothing(b.hash_value)
        b.hash_value = hash(b.operations)
    end
    b.hash_value - 3h
end


struct RepeatItem <: Abstractor
end

abs_keys(::Type{RepeatItem}) = ["item", "count"]
abstracts_types(::Type{RepeatItem}) = [Vector]

function to_abstract(::Type{RepeatItem}, value::Entry)
    items = []
    counts = []
    for vec_val in value.values
        if all(v == vec_val[1] for v in vec_val)
            push!(items, vec_val[1])
            push!(counts, length(vec_val))
        else
            return nothing
        end
    end
    item_type = value.type.parameters[1]
    return (Entry(item_type, items), Entry(counts))
end

function from_abstract(::Type{RepeatItem}, items_entry, counts_entry)
    result = []
    for (item, count) in zip(items_entry.values, counts_entry.values)
        push!(result, fill(item, count))
    end
    return (Entry(Vector{items_entry.type}, result),)
end

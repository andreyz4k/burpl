
struct RepeatItem <: Abstractor
end

abs_keys(::Type{RepeatItem}) = ["item", "count"]
abstracts_types(::Type{RepeatItem}) = [Vector]

return_types(::Type{RepeatItem}, type) = (type.parameters[1], Int64)

function to_abstract_inner(::Type{RepeatItem}, type, vec_val)
    if all(v == vec_val[1] for v in vec_val)
        return (vec_val[1], length(vec_val))
    else
        return nothing
    end
end

function from_abstract(::Type{RepeatItem}, items_entry, counts_entry)
    result = []
    for (item, count) in zip(items_entry.values, counts_entry.values)
        push!(result, fill(item, count))
    end
    return (Entry(Vector{items_entry.type}, result),)
end


struct UnwrapMatrix <: Abstractor end

abs_keys(::Type{UnwrapMatrix}) = ["items"]
abstracts_types(::Type{UnwrapMatrix}) = [Matrix]

return_types(::Type{UnwrapMatrix}, type) = (Vector{Tuple{type.parameters[1],Tuple{Int64,Int64}}}, )

using ..DataStructures: null_value, is_null_value

function to_abstract_inner(::Type{UnwrapMatrix}, type, matr_val)
    out_vals = []
    s = size(matr_val)
    item_type = type.parameters[1]
    null_val = null_value(item_type)
    for i = 1:s[1], j = 1:s[2]
        v = matr_val[i, j]
        if !is_null_value(v, null_val)
            push!(out_vals, (v, (i, j)))
        end
    end
    return (out_vals,)
end

function from_abstract(::Type{UnwrapMatrix}, items_entry)
    result = []
    for cell_list in items_entry.values
        grid_size = maximum.(v[2] for v in cell_list)
        grid = Matrix(undef, grid_size...)
        for (val, (i, j)) in cell_list
            grid[i, j] = val
        end
        push!(result, grid)
    end
    item_type = value.type.parameters[1].parameters[1]
    return (Entry(Matrix{item_type}, result),)
end

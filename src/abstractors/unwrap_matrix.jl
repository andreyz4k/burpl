
struct UnwrapMatrix <: Abstractor end

abs_keys(::Type{UnwrapMatrix}) = ["items"]
abstracts_types(::Type{UnwrapMatrix}) = [Matrix]

function to_abstract(::Type{UnwrapMatrix}, value::Entry)
    items = []
    for matr_val in value.values
        out_vals = []
        s = size(matr_val)
        for i in 1:s[1], j in 1:s[2]
            push!(out_vals, (matr_val[i, j], (i, j)))
        end
        push!(items, out_vals)
    end
    item_type = value.type.parameters[1]
    return (Entry(Vector{Tuple{item_type,Tuple{Int64,Int64}}}, items),)
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

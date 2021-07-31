
struct SolutionBranch
    known_fields::Dict{Any,Entry}
    unknown_fields::Dict{Any,Entry}
    fill_percentages::Dict{Any,Float64}
    operations::Vector{Operation}
    parent::Union{Nothing,SolutionBranch}
    children::Vector{SolutionBranch}
end

create_root_branch(known_fields, unknown_fields) = SolutionBranch(
    Dict(key => Entry(value) for (key, value) in known_fields),
    Dict(key => Entry(value) for (key, value) in unknown_fields),
    Dict(k => 0.0 for k in keys(unknown_fields)),
    [],
    nothing,
    [],
)

function Base.getindex(branch::SolutionBranch, key)
    if haskey(branch.known_fields, key)
        return branch.known_fields[key]
    elseif haskey(branch.unknown_fields, key)
        return branch.unknown_fields[key]
    elseif !isnothing(branch.parent)
        return branch.parent[key]
    else
        throw(KeyError(key))
    end
end

Base.show(io::IO, branch::SolutionBranch) = print(
    io,
    "SolutionBranch(\n",
    "\tknown_fields:\n",
    "\t\tDict(\n",
    ["\t\t\t\"$(keyval[1])\" => $(keyval[2]),\n" for keyval in branch.known_fields]...,
    "\t\t)\n",
    "\tunknown_fields:\n",
    "\t\tDict(\n",
    ["\t\t\t\"$(keyval[1])\" => $(keyval[2]),\n" for keyval in branch.unknown_fields]...,
    "\t\t)\n",
    "\tfill_percentages:\n",
    "\t\tDict(\n",
    ["\t\t\t\"$(keyval[1])\" => $(keyval[2]),\n" for keyval in branch.fill_percentages]...,
    "\t\t)\n",
    "\toperations:\n",
    "\t\t[\n",
    ["\t\t\t$op,\n" for op in branch.operations]...,
    "\t\t]\n",
    "\tchildren:\n",
    "\t\t[\n",
    ["\t\t$child,\n" for child in branch.children]...,
    "\t\t]\n)"
)

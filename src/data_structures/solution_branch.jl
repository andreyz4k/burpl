
struct SolutionBranch <: AbstractDict{Any,Any}
    known_fields::Dict{Any,Entry}
    unknown_fields::Dict{Any,Entry}
    fill_percentages::Dict{Any,Float64}
    operations::Vector{AbstractOperation}
    parent::Union{Nothing,SolutionBranch}
    children::Vector{SolutionBranch}
    either_groups::Vector{Set}
end

create_root_branch(known_fields, unknown_fields) = SolutionBranch(
    Dict(key => isa(value, Entry) ? value : Entry(value) for (key, value) in known_fields),
    Dict(key => isa(value, Entry) ? value : Entry(value) for (key, value) in unknown_fields),
    Dict(k => 0.0 for k in keys(unknown_fields)),
    [],
    nothing,
    [],
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
    "\teither_groups:\n\t\t",
    branch.either_groups,
    "\n",
    "\toperations:\n",
    "\t\t[\n",
    ["\t\t\t$op,\n" for op in branch.operations]...,
    "\t\t]\n",
    "\tchildren:\n",
    "\t\t[\n",
    ["\t\t$child,\n" for child in branch.children]...,
    "\t\t]\n)",
)

function Base.iterate(branch::SolutionBranch)
    return iterate(branch, (1, nothing))
end

function Base.iterate(branch::SolutionBranch, state::Tuple{Int,Any})
    br, internal_state = state
    if br == 1
        if isnothing(internal_state)
            next = iterate(branch.unknown_fields)
        else
            next = iterate(branch.unknown_fields, internal_state)
        end
        if isnothing(next)
            return iterate(branch, (2, nothing))
        end
        return next[1], (1, next[2])
    elseif br == 2
        if isnothing(internal_state)
            next = iterate(branch.known_fields)
        else
            next = iterate(branch.known_fields, internal_state)
        end
        if isnothing(next)
            return iterate(branch, (3, nothing))
        end
        return next[1], (2, next[2])
    elseif !isnothing(branch.parent)
        if isnothing(internal_state)
            next = iterate(branch.parent)
        else
            next = iterate(branch.parent, internal_state)
        end
        if isnothing(next)
            return nothing
        end
        if haskey(branch.unknown_fields, next[1][1]) || haskey(branch.known_fields, next[1][1])
            return iterate(branch, (3, next[2]))
        end
        return next[1], (3, next[2])
    end
end

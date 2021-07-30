
struct SolutionBranch
    known_fields::Dict{Any,Entry}
    unknown_fields::Dict{Any,Entry}
    fill_percentages::Dict{Any,Float64}
    operations::Vector{Operation}
    parent::Union{Nothing,SolutionBranch}
end

create_root_branch(known_fields, unknown_fields) = SolutionBranch(
    Dict(key => Entry(value) for (key, value) in known_fields),
    Dict(key => Entry(value) for (key, value) in unknown_fields),
    Dict(k => 0.0 for k in keys(unknown_fields)),
    [],
    nothing,
)

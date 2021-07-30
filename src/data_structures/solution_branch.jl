
struct SolutionBranch
    known_fields::Dict{Any,Vector{Entry}}
    unknown_fields::Dict{Any,Vector{Entry}}
    fill_percentages::Dict{Any,Float64}
    operations::Vector{Operation}
    parent::Union{Nothing,SolutionBranch}
end

create_root_branch(known_fields, unknown_fields) =
    SolutionBranch(known_fields, unknown_fields, Dict(k => 0.0 for k in keys(unknown_fields)), [], nothing)

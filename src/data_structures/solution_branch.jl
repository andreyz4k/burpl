
struct SolutionBranch
    data::Dict{Any,Vector{Entry}}
    operations::Vector
    parent::Union{Nothing,SolutionBranch}
end





struct SolutionFinder
    root_branch::SolutionBranch
end

create_finder(known_fields::Dict, unknown_fields::Dict) =
    SolutionFinder(create_root_branch(known_fields, unknown_fields))

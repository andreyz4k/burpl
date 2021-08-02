module PatternMatching

using ..DataStructures: Operation, Either

include("check_match.jl")
include("find_const.jl")
include("find_exact_match.jl")
include("mark_filled.jl")
include("match_field.jl")

end

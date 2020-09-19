using Test
include("../src/Randy.jl")
using .Randy
@testset "all" begin
    include("test_pattern_matching.jl")
    include("test_complexity.jl")
    include("test_object_prior.jl")
    include("test_group_objects.jl")
    # include("test_ignore_background.jl")
    include("test_compact_similar_objects.jl")
    # include("test_select_by_color.jl")
end

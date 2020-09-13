using Test
include("../src/Randy.jl")
using .Randy
@testset "all" begin
    include("test_complexity.jl")
    include("test_pattern_matching.jl")
end

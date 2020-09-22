using Test
include("../src/Randy.jl")
using .Randy
include("utils.jl")
using TestSetExtensions

@testset "all" begin
    @includetests ARGS
end

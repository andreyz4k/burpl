using Test
include("../src/Randy.jl")
using .Randy
include("utils.jl")
using TestSetExtensions

@testset ExtendedTestSet "all" begin
    @includetests ARGS
end

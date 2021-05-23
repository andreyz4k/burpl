using Test
include("../src/burpl.jl")
using .burpl
include("utils.jl")
using TestSetExtensions

@testset "all" begin
    @includetests ARGS
end

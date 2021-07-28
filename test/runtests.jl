using Test
include("../src/burpl.jl")
using .burpl
# include("utils.jl")
using TestSetExtensions

@testset ExtendedTestSet "all" begin
    @includetests ARGS
end

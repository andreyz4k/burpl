
using .Abstractors: wrap_check_task_value, SplitObject
using .PatternMatching: Either, Option
using .ObjectPrior: Object

@testset "Split object" begin
    @testset "split either object" begin
        value = Dict(2 => Object([2 2 2 2 2 2 2 2 2 2], (1, 6)), 8 => Object([8 8 8 8 8 8 8 8 8 8], (1, 8)))
        data = Dict("effective" => false)
        @test wrap_check_task_value(SplitObject(), value, data, []) == true

        value = Dict(
            3 => Object([3 3 3 3 3 3 3], (1, 9)),
            1 => Either([
                Option(Object([1 1 1 1 1 1 1], (1, 6)), 1519798033240906986),
                Option(Object([1 1 1 1 1 1 1], (1, 18)), -8964597388769226366),
            ]),
        )
        @test wrap_check_task_value(SplitObject(), value, data, []) == true
    end

    @testset "to abstract" begin
        value = make_taskdata(Dict{String,Any}("key" => Object([1; 1; 1; 1; 1; 1; 1], (1, 6))))
        splitter = SplitObject("key", true)
        out_data = splitter(value)
        @test out_data == Dict(
            "key" => Object([1; 1; 1; 1; 1; 1; 1], (1, 6)),
            "key|splitted" => Set([
                Object([1], (1, 6)),
                Object([1], (2, 6)),
                Object([1], (3, 6)),
                Object([1], (4, 6)),
                Object([1], (5, 6)),
                Object([1], (6, 6)),
                Object([1], (7, 6)),
            ]),
        )
        delete!(out_data, "key")
        splitter = SplitObject("key", false)
        reversed_data = splitter(out_data)
        @test reversed_data["key"] == value["key"]

        value = make_taskdata(
            Dict{String,Any}(
                "key" => Either([
                    Option(Object([1; 1; 1; 1; 1; 1; 1], (1, 6)), 1519798033240906986),
                    Option(Object([1; 1; 1; 1; 1; 1; 1], (1, 18)), -8964597388769226366),
                ]),
            ),
        )
        splitter = SplitObject("key", true)
        out_data = splitter(value)
        @test out_data == Dict(
            "key" => Either([
                Option(Object([1; 1; 1; 1; 1; 1; 1], (1, 6)), 1519798033240906986),
                Option(Object([1; 1; 1; 1; 1; 1; 1], (1, 18)), -8964597388769226366),
            ]),
            "key|splitted" => Either([
                Option(
                    Set([
                        Object([1], (1, 6)),
                        Object([1], (2, 6)),
                        Object([1], (3, 6)),
                        Object([1], (4, 6)),
                        Object([1], (5, 6)),
                        Object([1], (6, 6)),
                        Object([1], (7, 6)),
                    ]),
                    1519798033240906986,
                ),
                Option(
                    Set([
                        Object([1], (1, 18)),
                        Object([1], (2, 18)),
                        Object([1], (3, 18)),
                        Object([1], (4, 18)),
                        Object([1], (5, 18)),
                        Object([1], (6, 18)),
                        Object([1], (7, 18)),
                    ]),
                    -8964597388769226366,
                ),
            ]),
        )
    end
end

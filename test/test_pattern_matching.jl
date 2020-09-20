
using .SolutionOps:match_fields
using .PatternMatching:Either,make_either,Option,compare_values,update_value
using .ObjectPrior:Object

@testset "Patten Matching" begin

    @testset "make either" begin
        options = [
            (1, 2)
        ]
        keys = ("key1", "key2")
        @test make_either(keys, options) == Dict(
            "key1" => 1,
            "key2" => 2
        )
        options = [
            (1, 2),
            (3, 4)
        ]
        @test make_either(keys, options) == Dict(
            "key1" => Either([Option(1, hash((1, 2))), Option(3, hash((3, 4)))]),
            "key2" => Either([Option(2, hash((1, 2))), Option(4, hash((3, 4)))])
        )
        options = [1, 2]
        @test make_either(["key"], options) == Dict(
            "key" => Either([Option(1), Option(2)])
        )
    end

    @testset "match nested matcher" begin
        val1 = Object([1], (1, 6))
        val2 = Either([
            Option(Either([
                Option(Object([1], (1, 18)), -987741356063359383)
                Option(Object([1], (7, 18)), 5337975097275602430)
            ]), -6290834605491577753),
            Option(Either([
                Option(Object([1], (1, 6)), -1993017406633284401),
                Option(Object([1], (7, 6)), -8036724089052714593)
            ]), -1731569779980110441)
        ])
        @test compare_values(val1, val2) == val1
    end

    @testset "fix value" begin
        keys = ["spatial_objects|grouped|0|first|splitted|first", 1]
        value = Object([1], (0, 5))
        task_data = Dict(
            "spatial_objects|grouped|0|step" => Dict(
                1 => Either([
                    Option((0, 6), -1731569779980110441),
                    Option((0, -6), -6290834605491577753)
                ]),
                3 => (0, 6)
            ),
            "spatial_objects|grouped|0|first|splitted|first" => Dict(
                1 => Either([
                    Option(Either([
                        Option(Object([1],  (6, 17)), 5337975097275602430),
                        Option(Object([1],  (0, 17)), -987741356063359383)
                    ]), -6290834605491577753),
                    Option(Either([
                        Option(Object([1],  (6, 5)), -8036724089052714593),
                        Option(Object([1],  (0, 5)), -1993017406633284401)
                    ]), -1731569779980110441)
                ]),
                3 => Either([
                    Option(Object([3],  (0, 8)), 8357411015276601514),
                    Option(Object([3],  (6, 8)), -6298199269447202670)
                ])
            ),
            "spatial_objects|grouped|0|first|splitted|step" => Dict(
                1 => Either([
                    Option(Either([
                        Option((-1, 0), -8036724089052714593),
                        Option((1, 0), -1993017406633284401)
                    ]), -1731569779980110441),
                    Option(Either([
                        Option((1, 0), -987741356063359383),
                        Option((-1, 0), 5337975097275602430)
                    ]), -6290834605491577753)
                ]),
                3 => Either([
                    Option((-1, 0), -6298199269447202670),
                    Option((1, 0), 8357411015276601514)
                ])
            )
        )
        new_task_data = update_value(task_data, keys, value)

        @test new_task_data == Dict(
            "spatial_objects|grouped|0|step" => Dict(
                1 => (0, 6),
                3 => (0, 6)
            ),
            "spatial_objects|grouped|0|first|splitted|first" => Dict(
                1 => Object([1],  (0, 5)),
                3 => Either([
                    Option(Object([3],  (0, 8)), 8357411015276601514),
                    Option(Object([3],  (6, 8)), -6298199269447202670)
                ])
            ),
            "spatial_objects|grouped|0|first|splitted|step" => Dict(
                1 => (1, 0),
                3 => Either([
                    Option((-1, 0), -6298199269447202670),
                    Option((1, 0), 8357411015276601514)
                ])
            )
        )

        task_data = Dict(
            "spatial_objects|grouped|0|step" => Dict{Any,Any}(
                1 => Either([
                    Option((0, 6), -1731569779980110441),
                    Option((0, -6), -6290834605491577753)
                ]),
                3 => (0, 6)
            ),
            "spatial_objects|grouped|0|first|splitted|first" => Dict{Any,Any}(
                1 => Either([
                    Option(Either([
                        Option(Object([1],  (6, 17)), 5337975097275602430),
                        Option(Object([1],  (0, 17)), -987741356063359383)
                    ]), -6290834605491577753),
                    Option(Either([
                        Option(Object([1],  (6, 5))),
                        Option(Object([1],  (0, 5)))
                    ]), -1731569779980110441)
                ]),
                3 => Either([
                    Option(Object([3],  (0, 8)), 8357411015276601514),
                    Option(Object([3],  (6, 8)), -6298199269447202670)
                ])
            ),
            "spatial_objects|grouped|0|first|splitted|step" => Dict{Any,Any}(
                1 => Either([
                    Option(Either([
                        Option((-1, 0)),
                        Option((1, 0))
                    ]), -1731569779980110441),
                    Option(Either([
                        Option((1, 0)),
                        Option((-1, 0))
                    ]), -6290834605491577753)
                ]),
                3 => Either([
                    Option((-1, 0), -6298199269447202670),
                    Option((1, 0), 8357411015276601514)
                ])
            )
        )
        new_task_data = update_value(task_data, keys, value)
        @test new_task_data == Dict(
            "spatial_objects|grouped|0|step" => Dict(
                1 => (0, 6),
                3 => (0, 6)
            ),
            "spatial_objects|grouped|0|first|splitted|first" => Dict(
                1 => Object([1],  (0, 5)),
                3 => Either([
                    Option(Object([3],  (0, 8)), 8357411015276601514),
                    Option(Object([3],  (6, 8)), -6298199269447202670)
                ])
            ),
            "spatial_objects|grouped|0|first|splitted|step" => Dict(
                1 => Either([
                    Option((-1, 0)),
                    Option((1, 0))
                ]),
                3 => Either([
                    Option((-1, 0), -6298199269447202670),
                    Option((1, 0), 8357411015276601514)
                ])
            )
        )
    end

end

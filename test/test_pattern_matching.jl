
using .FindSolution:match_fields
using .PatternMatching:Either,make_either,Option,common_value,update_value,unpack_value
using .ObjectPrior:Object
using .Abstractors:iter_source_either_values

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
        @test common_value(val1, val2) == val1
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

    @testset "uneven either" begin
        options = [
            Option(Object([1], (6, 7)), 1466893429768792071),
            Option(Either([
                Option(Object([1], (18, 1)), 5711579767974711938),
                Option(Object([1], (18, 7)), 10665857197194304990)
            ]), 2852018346029524200)
        ]
        matcher = Either(options)
        @test unpack_value(matcher) == [
            Object([1], (6, 7)),
            Object([1], (18, 1)),
            Object([1], (18, 7))
        ]
    end

    @testset "unpack dict" begin
        value = Dict{Any,Any}(
            1 => Either([
                Option((2, 0), 15706271595680077155),
                Option((-2, 0), 2425360325578724088)
            ])
        )
        @test unpack_value(value) == [
            Dict(
                1 => (2, 0)
            ),
            Dict(
                1 => (-2, 0)
            )
        ]
    end

    @testset "unpack array" begin
        value = [
            Either([
                Option((2, 0), 15706271595680077155),
                Option((-2, 0), 2425360325578724088)
            ]),
            (1, 1)
        ]
        @test unpack_value(value) == [
            [(2, 0), (1, 1)],
            [(-2, 0), (1, 1)]
        ]
    end

    @testset "iterate either cases" begin
        vals = [1, 2, 3]
        @test iter_source_either_values(vals) == [([1, 2, 3], [], Set())]
        vals = [1, Either([Option(1), Option(2)])]
        @test iter_source_either_values(vals) == [
            ([1, 1], [], Set()),
            ([1, 2], [], Set())
        ]
        vals = [1, Either([Option(1), Option(2)]), Either([Option(3), Option(4)])]
        @test iter_source_either_values(vals) == [
            ([1, 1, 3], [], Set()),
            ([1, 2, 3], [], Set()),
            ([1, 1, 4], [], Set()),
            ([1, 2, 4], [], Set())
        ]
        vals = [1, Either([Option(1, 123), Option(2, 456)])]
        @test iter_source_either_values(vals) == [
            ([1, 1], [123], Set([123, 456])),
            ([1, 2], [456], Set([123, 456]))
        ]
        vals = [1, Either([Option(1, 123), Option(2, 456)]), Either([Option(3, 123), Option(4, 456)])]
        @test iter_source_either_values(vals) == [
            ([1, 1, 3], [123], Set([123, 456])),
            ([1, 2, 4], [456], Set([123, 456]))
        ]
        vals = [1, Either([Option(1, 123), Option(2, 456)]), Either([Option(3, 23), Option(4, 56)])]
        @test iter_source_either_values(vals) == [
            ([1, 1, 3], [123, 23], Set([123, 456, 23, 56])),
            ([1, 2, 3], [456, 23], Set([123, 456, 23, 56])),
            ([1, 1, 4], [123, 56], Set([123, 456, 23, 56])),
            ([1, 2, 4], [456, 56], Set([123, 456, 23, 56]))
        ]
        vals = [1, Either([Option(1, 123), Option(2, 456)]), Either([Option(3), Option(4)])]
        @test iter_source_either_values(vals) == [
            ([1, 1, 3], [123], Set([123, 456])),
            ([1, 2, 3], [456], Set([123, 456])),
            ([1, 1, 4], [123], Set([123, 456])),
            ([1, 2, 4], [456], Set([123, 456]))
        ]
        vals = [1, Either([Option(Either([Option(1), Option(3)])), Option(2)])]
        @test iter_source_either_values(vals) == [
            ([1, 1], [], Set()),
            ([1, 3], [], Set()),
            ([1, 2], [], Set()),
        ]
        vals = [1, Either([Option(Either([Option(1, 123), Option(2, 456)]), 54), Option(4, 209)])]
        @test iter_source_either_values(vals) == [
            ([1, 1], [54, 123], Set([123, 456, 54, 209])),
            ([1, 2], [54, 456], Set([123, 456, 54, 209])),
            ([1, 4], [209], Set([123, 456, 54, 209]))
        ]
    end

end

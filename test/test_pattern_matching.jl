
using .FindSolution: match_fields
using .PatternMatching:
    Either,
    make_either,
    Option,
    common_value,
    update_value,
    unpack_value,
    SubSet,
    ObjectShape,
    Matcher,
    check_match,
    AuxValue
using .ObjectPrior: Object
using .Abstractors: iter_source_either_values

@testset "Patten Matching" begin

    @testset "make either" begin
        options = [(1, 2)]
        keys = ("key1", "key2")
        @test make_either(keys, options) == Dict("key1" => 1, "key2" => 2)
        options = [(1, 2), (3, 4)]
        @test make_either(keys, options) == Dict(
            "key1" => Either([Option(1, hash((1, 2))), Option(3, hash((3, 4)))]),
            "key2" => Either([Option(2, hash((1, 2))), Option(4, hash((3, 4)))]),
        )
        options = [1, 2]
        @test make_either(["key"], options) == Dict("key" => Either([Option(1), Option(2)]))
    end

    @testset "match nested matcher" begin
        val1 = Object([1], (1, 6))
        val2 = Either([
            Option(
                Either(
                    [
                        Option(Object([1], (1, 18)), -987741356063359383)
                        Option(Object([1], (7, 18)), 5337975097275602430)
                    ],
                ),
                -6290834605491577753,
            ),
            Option(
                Either([
                    Option(Object([1], (1, 6)), -1993017406633284401),
                    Option(Object([1], (7, 6)), -8036724089052714593),
                ]),
                -1731569779980110441,
            ),
        ])
        @test common_value(val1, val2) == val1
    end

    @testset "fix value" begin
        keys = ["spatial_objects|grouped|0|first|splitted|first", 1]
        value = Object([1], (0, 5))
        task_data = make_taskdata(
            Dict(
                "spatial_objects|grouped|0|step" => Dict(
                    1 => Either([Option((0, 6), -1731569779980110441), Option((0, -6), -6290834605491577753)]),
                    3 => (0, 6),
                ),
                "spatial_objects|grouped|0|first|splitted|first" => Dict(
                    1 => Either([
                        Option(
                            Either([
                                Option(Object([1], (6, 17)), 5337975097275602430),
                                Option(Object([1], (0, 17)), -987741356063359383),
                            ]),
                            -6290834605491577753,
                        ),
                        Option(
                            Either([
                                Option(Object([1], (6, 5)), -8036724089052714593),
                                Option(Object([1], (0, 5)), -1993017406633284401),
                            ]),
                            -1731569779980110441,
                        ),
                    ]),
                    3 => Either([
                        Option(Object([3], (0, 8)), 8357411015276601514),
                        Option(Object([3], (6, 8)), -6298199269447202670),
                    ]),
                ),
                "spatial_objects|grouped|0|first|splitted|step" => Dict(
                    1 => Either([
                        Option(
                            Either([Option((-1, 0), -8036724089052714593), Option((1, 0), -1993017406633284401)]),
                            -1731569779980110441,
                        ),
                        Option(
                            Either([Option((1, 0), -987741356063359383), Option((-1, 0), 5337975097275602430)]),
                            -6290834605491577753,
                        ),
                    ]),
                    3 => Either([Option((-1, 0), -6298199269447202670), Option((1, 0), 8357411015276601514)]),
                ),
            ),
        )
        new_task_data = update_value(task_data, keys, value)

        @test Dict(new_task_data) == Dict(
            "spatial_objects|grouped|0|step" => Dict(1 => (0, 6), 3 => (0, 6)),
            "spatial_objects|grouped|0|first|splitted|first" => Dict(
                1 => Object([1], (0, 5)),
                3 => Either([
                    Option(Object([3], (0, 8)), 8357411015276601514),
                    Option(Object([3], (6, 8)), -6298199269447202670),
                ]),
            ),
            "spatial_objects|grouped|0|first|splitted|step" => Dict(
                1 => (1, 0),
                3 => Either([Option((-1, 0), -6298199269447202670), Option((1, 0), 8357411015276601514)]),
            ),
        )

        task_data = make_taskdata(
            Dict(
                "spatial_objects|grouped|0|step" => Dict{Any,Any}(
                    1 => Either([Option((0, 6), -1731569779980110441), Option((0, -6), -6290834605491577753)]),
                    3 => (0, 6),
                ),
                "spatial_objects|grouped|0|first|splitted|first" => Dict{Any,Any}(
                    1 => Either([
                        Option(
                            Either([
                                Option(Object([1], (6, 17)), 5337975097275602430),
                                Option(Object([1], (0, 17)), -987741356063359383),
                            ]),
                            -6290834605491577753,
                        ),
                        Option(
                            Either([Option(Object([1], (6, 5))), Option(Object([1], (0, 5)))]),
                            -1731569779980110441,
                        ),
                    ]),
                    3 => Either([
                        Option(Object([3], (0, 8)), 8357411015276601514),
                        Option(Object([3], (6, 8)), -6298199269447202670),
                    ]),
                ),
                "spatial_objects|grouped|0|first|splitted|step" => Dict{Any,Any}(
                    1 => Either([
                        Option(Either([Option((-1, 0)), Option((1, 0))]), -1731569779980110441),
                        Option(Either([Option((1, 0)), Option((-1, 0))]), -6290834605491577753),
                    ]),
                    3 => Either([Option((-1, 0), -6298199269447202670), Option((1, 0), 8357411015276601514)]),
                ),
            ),
        )
        new_task_data = update_value(task_data, keys, value)
        @test Dict(new_task_data) == Dict(
            "spatial_objects|grouped|0|step" => Dict(1 => (0, 6), 3 => (0, 6)),
            "spatial_objects|grouped|0|first|splitted|first" => Dict(
                1 => Object([1], (0, 5)),
                3 => Either([
                    Option(Object([3], (0, 8)), 8357411015276601514),
                    Option(Object([3], (6, 8)), -6298199269447202670),
                ]),
            ),
            "spatial_objects|grouped|0|first|splitted|step" => Dict(
                1 => Either([Option((-1, 0)), Option((1, 0))]),
                3 => Either([Option((-1, 0), -6298199269447202670), Option((1, 0), 8357411015276601514)]),
            ),
        )
    end

    @testset "uneven either" begin
        options = [
            Option(Object([1], (6, 7)), 1466893429768792071),
            Option(
                Either([
                    Option(Object([1], (18, 1)), 5711579767974711938),
                    Option(Object([1], (18, 7)), 10665857197194304990),
                ]),
                2852018346029524200,
            ),
        ]
        matcher = Either(options)
        @test unpack_value(matcher) == [Object([1], (6, 7)), Object([1], (18, 1)), Object([1], (18, 7))]
    end

    @testset "unpack dict" begin
        value = Dict{Any,Any}(1 => Either([Option((2, 0), 15706271595680077155), Option((-2, 0), 2425360325578724088)]))
        @test unpack_value(value) == [Dict(1 => (2, 0)), Dict(1 => (-2, 0))]
    end

    @testset "unpack array" begin
        value = [Either([Option((2, 0), 15706271595680077155), Option((-2, 0), 2425360325578724088)]), (1, 1)]
        @test unpack_value(value) == [[(2, 0), (1, 1)], [(-2, 0), (1, 1)]]
    end

    @testset "iterate either cases" begin
        vals = [1, 2, 3]
        @test iter_source_either_values(vals) == [([1, 2, 3], [], Set())]
        vals = [1, Either([Option(1), Option(2)])]
        @test iter_source_either_values(vals) == [([1, 1], [], Set()), ([1, 2], [], Set())]
        vals = [1, Either([Option(1), Option(2)]), Either([Option(3), Option(4)])]
        @test iter_source_either_values(vals) ==
              [([1, 1, 3], [], Set()), ([1, 2, 3], [], Set()), ([1, 1, 4], [], Set()), ([1, 2, 4], [], Set())]
        vals = [1, Either([Option(1, 123), Option(2, 456)])]
        @test iter_source_either_values(vals) == [([1, 1], [123], Set([123, 456])), ([1, 2], [456], Set([123, 456]))]
        vals = [1, Either([Option(1, 123), Option(2, 456)]), Either([Option(3, 123), Option(4, 456)])]
        @test iter_source_either_values(vals) ==
              [([1, 1, 3], [123], Set([123, 456])), ([1, 2, 4], [456], Set([123, 456]))]
        vals = [1, Either([Option(1, 123), Option(2, 456)]), Either([Option(3, 23), Option(4, 56)])]
        @test iter_source_either_values(vals) == [
            ([1, 1, 3], [123, 23], Set([123, 456, 23, 56])),
            ([1, 2, 3], [456, 23], Set([123, 456, 23, 56])),
            ([1, 1, 4], [123, 56], Set([123, 456, 23, 56])),
            ([1, 2, 4], [456, 56], Set([123, 456, 23, 56])),
        ]
        vals = [1, Either([Option(1, 123), Option(2, 456)]), Either([Option(3), Option(4)])]
        @test iter_source_either_values(vals) == [
            ([1, 1, 3], [123], Set([123, 456])),
            ([1, 2, 3], [456], Set([123, 456])),
            ([1, 1, 4], [123], Set([123, 456])),
            ([1, 2, 4], [456], Set([123, 456])),
        ]
        vals = [1, Either([Option(Either([Option(1), Option(3)])), Option(2)])]
        @test iter_source_either_values(vals) == [([1, 1], [], Set()), ([1, 3], [], Set()), ([1, 2], [], Set())]
        vals = [1, Either([Option(Either([Option(1, 123), Option(2, 456)]), 54), Option(4, 209)])]
        @test iter_source_either_values(vals) == [
            ([1, 1], [54, 123], Set([123, 456, 54, 209])),
            ([1, 2], [54, 456], Set([123, 456, 54, 209])),
            ([1, 4], [209], Set([123, 456, 54, 209])),
        ]
    end

    @testset "order values in subset" begin
        a = SubSet(Set{Int}([3, 2, 1]))
        b = SubSet(Set{Int}([2, 1]))
        c = common_value(a, b)
        @test unpack_value(c)[1][3] == 3
        d = SubSet(Set{Int}([1]))
        e = common_value(c, d)
        @test unpack_value(e)[1] == [1, 2, 3]
    end

    @testset "match counted array of shapes" begin
        a = SubSet(
            ObjectShape{Object}[
                ObjectShape(Object([2], (1, 2))),
                ObjectShape(
                    Object(
                        [
                            -1 -1 -1 2 2 2 2 -1 2 2
                            2 -1 2 2 2 2 2 2 2 -1
                            2 2 2 2 2 2 -1 2 2 2
                            2 2 2 2 2 2 2 -1 2 2
                            -1 2 2 -1 2 2 2 -1 2 -1
                            -1 -1 2 2 2 -1 -1 2 2 2
                            2 -1 2 2 -1 -1 -1 2 2 2
                            2 2 -1 2 2 -1 -1 -1 2 2
                            2 2 2 2 -1 -1 -1 -1 2 2
                            2 2 -1 2 -1 -1 -1 2 2 2
                        ],
                        (1, 1),
                    ),
                ),
                ObjectShape(Object([2], (7, 6))),
                ObjectShape(Object([2; 2], (9, 6))),
            ],
        )
        b = Object[
            Object([2], (1, 13)),
            Object(
                [
                    -1 -1 -1 2 2 2 2 -1 2 2
                    2 -1 2 2 2 2 2 2 2 -1
                    2 2 2 2 2 2 -1 2 2 2
                    2 2 2 2 2 2 2 -1 2 2
                    -1 2 2 -1 2 2 2 -1 2 -1
                    -1 -1 2 2 2 -1 -1 2 2 2
                    2 -1 2 2 -1 -1 -1 2 2 2
                    2 2 -1 2 2 -1 -1 -1 2 2
                    2 2 2 2 -1 -1 -1 -1 2 2
                    2 2 -1 2 -1 -1 -1 2 2 2
                ],
                (1, 12),
            ),
            Object([2], (7, 17)),
            Object([2; 2], (9, 17)),
        ]
        @test check_match(b, a)
        c = Object[
            Object([2], (1, 13)),
            Object(
                [
                    -1 -1 -1 2 2 2 2 -1 2 2
                    2 -1 2 2 2 2 2 2 2 -1
                    2 2 2 2 2 2 -1 2 2 2
                    2 2 2 2 2 2 2 -1 2 2
                    -1 2 2 -1 2 2 2 -1 2 -1
                    -1 -1 2 2 2 -1 -1 2 2 2
                    2 -1 2 2 -1 -1 -1 2 2 2
                    2 2 -1 2 2 -1 -1 -1 2 2
                    2 2 2 2 -1 -1 -1 -1 2 2
                    2 2 -1 2 -1 -1 -1 2 2 2
                ],
                (1, 12),
            ),
            Object([2 2], (8, 17)),
            Object([2; 2], (9, 17)),
        ]
        @test !check_match(c, a)
        d = Object[
            Object([2], (1, 13)),
            Object(
                [
                    -1 -1 -1 2 2 2 2 -1 2 2
                    2 -1 2 2 2 2 2 2 2 -1
                    2 2 2 2 2 2 -1 2 2 2
                    2 2 2 2 2 2 2 -1 2 2
                    -1 2 2 -1 2 2 2 -1 2 -1
                    -1 -1 2 2 2 -1 -1 2 2 2
                    2 -1 2 2 -1 -1 -1 2 2 2
                    2 2 -1 2 2 -1 -1 -1 2 2
                    2 2 2 2 -1 -1 -1 -1 2 2
                    2 2 -1 2 -1 -1 -1 2 2 2
                ],
                (1, 12),
            ),
            Object([2], (7, 17)),
        ]
        @test !check_match(d, a)
        e = Object[
            Object([2], (1, 13)),
            Object(
                [
                    -1 -1 -1 2 2 2 2 -1 2 2
                    2 -1 2 2 2 2 2 2 2 -1
                    2 2 2 2 2 2 -1 2 2 2
                    2 2 2 2 2 2 2 -1 2 2
                    -1 2 2 -1 2 2 2 -1 2 -1
                    -1 -1 2 2 2 -1 -1 2 2 2
                    2 -1 2 2 -1 -1 -1 2 2 2
                    2 2 -1 2 2 -1 -1 -1 2 2
                    2 2 2 2 -1 -1 -1 -1 2 2
                    2 2 -1 2 -1 -1 -1 2 2 2
                ],
                (1, 12),
            ),
            Object([2], (7, 17)),
            Object([2; 2], (9, 17)),
            Object([2 2], (8, 17)),
        ]
        @test check_match(e, a)
    end

    @testset "match either of subsets" begin
        a = Either([
            Option(
                Either([
                    Option(SubSet(Set([Object([0], (2, 1)), Object([0], (1, 2))])), 13303829909579842466),
                    Option(SubSet(Set([Object([0], (1, 1)), Object([0], (2, 2))])), 6573933442709006643),
                ]),
                7969767543712303777,
            ),
            Option(
                Either([
                    Option(SubSet(Set([Object([0], (2, 1)), Object([0], (1, 2))])), 14134205155490256176),
                    Option(SubSet(Set([Object([0], (1, 1)), Object([0], (2, 2))])), 4314826064247553369),
                ]),
                8389884921107435457,
            ),
        ])
        b = Object[Object([0], (1, 1)), Object([0], (2, 2)), Object([0], (3, 3)), Object([0], (4, 4))]
        c = Either([
            Option(SubSet(Set([Object([0], (2, 1)), Object([0], (1, 2))])), 13303829909579842466),
            Option(SubSet(Set([Object([0], (1, 1)), Object([0], (2, 2))])), 6573933442709006643),
        ])
        d = SubSet(Set([Object([0], (1, 1)), Object([0], (2, 2))]))
        e = [Object([0], (1, 1)), Object([0], (2, 2))]
        @test check_match(b, a)
        @test check_match(b, c)
        @test check_match(b, d)
        @test check_match(e, d)
    end

    @testset "match nested either with aux" begin
        taskdata = make_taskdata(
            Dict(
                "vert_kernel|horz_kernel|splitted|first" => Either([
                    Option(
                        Either([
                            Option(Object([0], (2, 2)), 2229600132097324827),
                            Option(
                                Either([
                                    Option(Object([0], (1, 2)), 17375691416059178657),
                                    Option(Object([0], (2, 1)), 7846536631665789771),
                                ]),
                                8454689442923949871,
                            ),
                            Option(Object([0], (2, 2)), 9066318667632083547),
                            Option(
                                Either([
                                    Option(Object([0], (2, 3)), 2793800711255044032),
                                    Option(Object([0], (1, 2)), 16699880208097204678),
                                ]),
                                2841229356805458503,
                            ),
                        ]),
                        14914076444286691944,
                    ),
                    Option(
                        Either([
                            Option(Object([0], (2, 2)), 15068936698137099477),
                            Option(Object([0], (2, 2)), 9455476612018608109),
                            Option(
                                Either([
                                    Option(Object([0], (3, 2)), 10804414570319185252),
                                    Option(Object([0], (2, 1)), 6263381081530699870),
                                ]),
                                15680565922845233153,
                            ),
                            Option(
                                Either([
                                    Option(Object([0], (3, 2)), 13064878422929315778),
                                    Option(Object([0], (2, 3)), 4146920221692058636),
                                ]),
                                8843847387310474433,
                            ),
                        ]),
                        15081192867680029596,
                    ),
                    Option(
                        Either([
                            Option(Object([0], (2, 2)), 2229600132097324827),
                            Option(
                                Either([
                                    Option(Object([0], (1, 2)), 17375691416059178657),
                                    Option(Object([0], (2, 1)), 7846536631665789771),
                                ]),
                                8454689442923949871,
                            ),
                            Option(Object([0], (2, 2)), 9066318667632083547),
                            Option(
                                Either([
                                    Option(Object([0], (2, 3)), 2793800711255044032),
                                    Option(Object([0], (1, 2)), 16699880208097204678),
                                ]),
                                2841229356805458503,
                            ),
                        ]),
                        895491277412430600,
                    ),
                    Option(
                        Either([
                            Option(Object([0], (2, 2)), 15068936698137099477),
                            Option(Object([0], (2, 2)), 9455476612018608109),
                            Option(
                                Either([
                                    Option(Object([0], (3, 2)), 10804414570319185252),
                                    Option(Object([0], (2, 1)), 6263381081530699870),
                                ]),
                                15680565922845233153,
                            ),
                            Option(
                                Either([
                                    Option(Object([0], (3, 2)), 13064878422929315778),
                                    Option(Object([0], (2, 3)), 4146920221692058636),
                                ]),
                                8843847387310474433,
                            ),
                        ]),
                        1062607700805768252,
                    ),
                ]),
                "vert_kernel|horz_kernel|splitted|step" => Either([
                    Option(
                        Either([
                            Option((-1, 1), 2229600132097324827),
                            Option(
                                Either([Option((1, -1), 17375691416059178657), Option((-1, 1), 7846536631665789771)]),
                                8454689442923949871,
                            ),
                            Option((-1, -1), 9066318667632083547),
                            Option(
                                Either([Option((-1, -1), 2793800711255044032), Option((1, 1), 16699880208097204678)]),
                                2841229356805458503,
                            ),
                        ]),
                        14914076444286691944,
                    ),
                    Option(
                        Either([
                            Option((1, -1), 15068936698137099477),
                            Option((1, 1), 9455476612018608109),
                            Option(
                                Either([Option((-1, -1), 10804414570319185252), Option((1, 1), 6263381081530699870)]),
                                15680565922845233153,
                            ),
                            Option(
                                Either([Option((-1, 1), 13064878422929315778), Option((1, -1), 4146920221692058636)]),
                                8843847387310474433,
                            ),
                        ]),
                        15081192867680029596,
                    ),
                    Option(
                        Either([
                            Option((-1, 1), 2229600132097324827),
                            Option(
                                Either([Option((1, -1), 17375691416059178657), Option((-1, 1), 7846536631665789771)]),
                                8454689442923949871,
                            ),
                            Option((-1, -1), 9066318667632083547),
                            Option(
                                Either([Option((-1, -1), 2793800711255044032), Option((1, 1), 16699880208097204678)]),
                                2841229356805458503,
                            ),
                        ]),
                        895491277412430600,
                    ),
                    Option(
                        Either([
                            Option((1, -1), 15068936698137099477),
                            Option((1, 1), 9455476612018608109),
                            Option(
                                Either([Option((-1, -1), 10804414570319185252), Option((1, 1), 6263381081530699870)]),
                                15680565922845233153,
                            ),
                            Option(
                                Either([Option((-1, 1), 13064878422929315778), Option((1, -1), 4146920221692058636)]),
                                8843847387310474433,
                            ),
                        ]),
                        1062607700805768252,
                    ),
                ]),
                "vert_is_left" => AuxValue(
                    Either([
                        Option(true, 895491277412430600),
                        Option(true, 14914076444286691944),
                        Option(false, 1062607700805768252),
                        Option(false, 15081192867680029596),
                    ]),
                ),
                "vert_kernel|horz_is_top" => Either([
                    Option(
                        AuxValue(
                            Either([
                                Option(true, 8454689442923949871),
                                Option(true, 9066318667632083547),
                                Option(false, 2229600132097324827),
                                Option(false, 2841229356805458503),
                            ]),
                        ),
                        14914076444286691944,
                    ),
                    Option(
                        AuxValue(
                            Either([
                                Option(true, 15068936698137099477),
                                Option(true, 15680565922845233153),
                                Option(false, 8843847387310474433),
                                Option(false, 9455476612018608109),
                            ]),
                        ),
                        15081192867680029596,
                    ),
                    Option(
                        AuxValue(
                            Either([
                                Option(true, 9066318667632083547),
                                Option(true, 8454689442923949871),
                                Option(false, 2841229356805458503),
                                Option(false, 2229600132097324827),
                            ]),
                        ),
                        895491277412430600,
                    ),
                    Option(
                        AuxValue(
                            Either([
                                Option(true, 15680565922845233153),
                                Option(true, 15068936698137099477),
                                Option(false, 9455476612018608109),
                                Option(false, 8843847387310474433),
                            ]),
                        ),
                        1062607700805768252,
                    ),
                ]),
            ),
        )
        new_data = update_value(taskdata, "vert_kernel|horz_kernel|splitted|step", (-1, -1))
        @test new_data == Dict(
            "vert_kernel|horz_kernel|splitted|first" => Either([
                Option(
                    Either([
                        Option(Object([0], (2, 2)), 9066318667632083547),
                        Option(Object([0], (2, 3)), 2841229356805458503),
                    ]),
                    14914076444286691944,
                ),
                Option(Object([0], (3, 2)), 15081192867680029596),
                Option(
                    Either([
                        Option(Object([0], (2, 2)), 9066318667632083547),
                        Option(Object([0], (2, 3)), 2841229356805458503),
                    ]),
                    895491277412430600,
                ),
                Option(Object([0], (3, 2)), 1062607700805768252),
            ]),
            "vert_kernel|horz_kernel|splitted|step" => (-1, -1),
            "vert_is_left" => AuxValue(
                Either([
                    Option(true, 895491277412430600),
                    Option(true, 14914076444286691944),
                    Option(false, 1062607700805768252),
                    Option(false, 15081192867680029596),
                ]),
            ),
            "vert_kernel|horz_is_top" => Either([
                Option(
                    AuxValue(Either([Option(true, 9066318667632083547), Option(false, 2841229356805458503)])),
                    14914076444286691944,
                ),
                Option(AuxValue(true), 15081192867680029596),
                Option(
                    AuxValue(Either([Option(true, 9066318667632083547), Option(false, 2841229356805458503)])),
                    895491277412430600,
                ),
                Option(AuxValue(true), 1062607700805768252),
            ]),
        )
    end
end

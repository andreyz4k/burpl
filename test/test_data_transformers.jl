
using .PatternMatching:Either,Option
using .DataTransformers:find_const,SetConst,CopyParam
using .SolutionOps:match_fields

@testset "Data transformers" begin
    @testset "find const" begin
        taskdata = [
                Dict{String,Any}(
                    "background" => 1
                ),
                Dict{String,Any}(
                    "background" => 1
                )
            ]

        @test find_const(taskdata, [], "background") == [SetConst("background", 1)]

        taskdata = [
                Dict{String,Any}(
                    "background" => 1
                ),
                Dict{String,Any}(
                    "background" => Either([1, 2])
                )
            ]

        @test find_const(taskdata, [], "background") == [SetConst("background", 1)]

        taskdata = [
                Dict{String,Any}(
                    "background" => Either([1, 2])
                ),
                Dict{String,Any}(
                    "background" => 1
                ),
            ]

        @test find_const(taskdata, [], "background") == [SetConst("background", 1)]

        taskdata = [
                Dict{String,Any}(
                    "background" => Either([1, 2])
                ),
                Dict{String,Any}(
                    "background" => Either([1, 3])
                ),
            ]

        @test find_const(taskdata, [], "background") == [SetConst("background", 1)]

        taskdata = [
                Dict{String,Any}(
                    "background" => Either([1, 2])
                ),
                Dict{String,Any}(
                    "background" => Either([1, 2])
                ),
            ]

        @test issetequal(find_const(taskdata, [], "background"), [SetConst("background", 1), SetConst("background", 2)])
    end

    @testset "match dicts" begin
        taskdata = [
            Dict{String,Any}(
                "key" => Dict(
                    1 => 1,
                    2 => 2
                )
            ),
            Dict{String,Any}(
                "key" => Dict(
                    1 => 1,
                    2 => 2
                )
            )
        ]
        @test find_const(taskdata, [], "key") == [SetConst("key", Dict(2 => 2, 1 => 1))]

        taskdata = [
            Dict{String,Any}(
                "key" => Dict(
                    1 => 1,
                    2 => 2
                )
            ),
            Dict{String,Any}(
                "key" => Dict(
                    1 => Either([1, 3]),
                    2 => 2
                )
            )
        ]
        @test find_const(taskdata, [], "key") == [SetConst("key", Dict(
            1 => 1,
            2 => 2
        ))]
    end

    @testset "match data" begin
        solution = make_dummy_solution([
               Dict(
                    "background" => 1
                ),
                Dict(
                    "background" => 1
                )
            ],
            ["background"]
        )
        new_solutions = match_fields(solution)
        @test length(new_solutions) == 1
        new_solution = new_solutions[1]
        @test new_solution.blocks[end].operations == [SetConst("background", 1)]
    end

    @testset "match either" begin
        solution = make_dummy_solution([
            Dict(
                "background" => Either([1, 2])
            ),
            Dict(
                "background" => Either([1, 2])
            ),
        ], ["background"])
        new_solutions = match_fields(solution)
        @test length(new_solutions) == 2
        expected_operations = Set([
            [SetConst("background", 1)],
            [SetConst("background", 2)]
        ])
        _compare_operations(expected_operations, new_solutions)
        @test filtered_taskdata(new_solutions[1]) != [
            Dict(
                "background" => Either([1, 2])
            ),
            Dict(
                "background" => Either([1, 2])
            ),
        ]
        @test new_solutions[1].taskdata != new_solutions[2].taskdata
        @test filtered_taskdata(solution) == [
            Dict(
                "background" => Either([1, 2])
            ),
            Dict(
                "background" => Either([1, 2])
            ),
        ]
    end

    @testset "match two fields" begin
        solution = make_dummy_solution([
            Dict(
                "background" => Either([1, 2]),
                "key2" => 23,
                "background_in" => 1
            ),
            Dict(
                "background" => Either([1, 2]),
                "key2" => 32,
                "background_in" => 2
            ),
        ], ["background", "key2"])
        new_solutions = match_fields(solution)
        @test length(new_solutions) == 3
        expected_operations = Set([
            [SetConst("background", 1)],
            [SetConst("background", 2)],
            [CopyParam("background", "background_in")],
            # [MapValues("key2", "background_in", Dict(1=>23, 2=>32)), SetConst("background", 1)],
            # [MapValues("key2", "background_in", Dict(1=>23, 2=>32)), SetConst("background", 2)],
            # [MapValues("key2", "background_in", Dict(1=>23, 2=>32)),
            # CopyParam("background", "background_in")],
            # [CopyParam("background", "background_in"),
            # MapValues("key2", "background", Dict(1=>23, 2=>32))],
        ])
        _compare_operations(expected_operations, new_solutions)
        @test filtered_taskdata(solution) == [
            Dict(
                "background" => Either([1, 2]),
                "key2" => 23,
                "background_in" => 1
            ),
            Dict(
                "background" => Either([1, 2]),
                "key2" => 32,
                "background_in" => 2
            ),
        ]
    end

    @testset "either hash fix" begin
        solution = make_dummy_solution([
            Dict(
                "key1" => Either([Option(1, hash((1, 2))), Option(3, hash((3, 4)))]),
                "key2" => Either([Option(2, hash((1, 2))), Option(4, hash((3, 4)))])
            ),
            Dict(
                "key1" => 1,
                "key2" => Either([Option(2, hash((1, 2))), Option(4, hash((3, 4)))])
            )
        ], ["key1", "key2"])
        new_solutions = match_fields(solution)
        @test length(new_solutions) == 2
        @test Set(new_solutions[1].blocks[end].operations) ==
                         Set([SetConst("key1", 1), SetConst("key2", 2)])
        @test filtered_taskdata(new_solutions[1]) == [
            Dict(
                "key1" => 1,
                "key2" => 2
            ),
            Dict(
                "key1" => 1,
                "key2" => 2
            )
        ]
        @test new_solutions[2].blocks[end].operations == [SetConst("key2", 4)]
        @test filtered_taskdata(new_solutions[2]) == [
            Dict(
                "key1" => 3,
                "key2" => 4
            ),
            Dict(
                "key1" => 1,
                "key2" => 4
            )
        ]
        @test filtered_taskdata(solution) == [
            Dict(
                "key1" => Either([Option(1, hash((1, 2))), Option(3, hash((3, 4)))]),
                "key2" => Either([Option(2, hash((1, 2))), Option(4, hash((3, 4)))])
            ),
            Dict(
                "key1" => 1,
                "key2" => Either([Option(2, hash((1, 2))), Option(4, hash((3, 4)))])
            )
        ]
    end

    @testset "either hash fix 2" begin
        solution = make_dummy_solution([
            Dict(
                "key1" => Either([Option(1, hash((1, 2))), Option(3, hash((3, 4)))]),
                "key2" => Either([Option(2, hash((1, 2))), Option(4, hash((3, 4)))]),
                "key3" => 1
            ),
            Dict(
                "key1" => Either([Option(4, hash((4, 5))), Option(6, hash((6, 7)))]),
                "key2" => Either([Option(5, hash((4, 5))), Option(7, hash((6, 7)))]),
                "key3" => 6
            ),
            Dict(
                "key1" => Either([Option(1, hash((1, 3))), Option(3, hash((3, 4)))]),
                "key2" => Either([Option(3, hash((1, 3))), Option(4, hash((3, 4)))]),
                "key3" => 1
            ),
        ],["key1", "key2"])
        new_solutions = match_fields(solution)
        @test length(new_solutions) == 1
        @test new_solutions[1].blocks[end].operations == [CopyParam("key1", "key3")]
        @test issetequal(new_solutions[1].unfilled_fields, ["key2"])
        @test filtered_taskdata(new_solutions[1]) == [Dict("key1" => 1, "key2" => 2, "key3" => 1),
                                            Dict("key1" => 6, "key2" => 7, "key3" => 6),
                                            Dict("key1" => 1, "key2" => 3, "key3" => 1)]
        @test filtered_taskdata(solution) == [
            Dict(
                "key1" => Either([Option(1, hash((1, 2))), Option(3, hash((3, 4)))]),
                "key2" => Either([Option(2, hash((1, 2))), Option(4, hash((3, 4)))]),
                "key3" => 1
            ),
            Dict(
                "key1" => Either([Option(4, hash((4, 5))), Option(6, hash((6, 7)))]),
                "key2" => Either([Option(5, hash((4, 5))), Option(7, hash((6, 7)))]),
                "key3" => 6
            ),
            Dict(
                "key1" => Either([Option(1, hash((1, 3))), Option(3, hash((3, 4)))]),
                "key2" => Either([Option(3, hash((1, 3))), Option(4, hash((3, 4)))]),
                "key3" => 1
            ),
        ]
    end

    @testset "match nested either" begin
        solution = make_dummy_solution([
            Dict(
                "spatial_objects|grouped|0" => Dict(
                    8 => Object([8], (9, 7)),
                    2 => Object([2], (0, 5))
                ),
                "spatial_objects|grouped|0|step" => Dict(2 => (0, 4), 8 => (0, 4)),
                "spatial_objects|grouped|0|first|splitted|first" => Dict(
                    2 => Either([
                        Option(
                            Object([2], (0, 5)),
                            -8357220665304833330),
                        Option(
                            Object([2], (9, 5)),
                            -7774447106926069087)
                    ]),
                    8 => Either([
                        Option(
                            Object([8], (9, 7)),
                            -7449978942198423200
                        ),
                        Option(
                            Object([8], (0, 7)),
                            -556451181567613247)
                    ])
                ),
                "spatial_objects|grouped|0|first|splitted|step" => Dict(
                    2 => Either([
                        Option((-1, 0), -7774447106926069087),
                        Option((1, 0), -8357220665304833330)
                    ]),
                    8 => Either([
                        Option((-1, 0), -7449978942198423200),
                        Option((1, 0), -556451181567613247)
                    ])
                )
            ),
            Dict(
                "spatial_objects|grouped|0" => Dict(
                    3 => Object([3], (6, 8)),
                    1 => Object([1], (0, 5))
                ),
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
                            Option(Object([1], (0, 17)), -987741356063359383),
                            Option(Object([1], (6, 17)), 5337975097275602430)
                        ]), -6290834605491577753),
                        Option(Either([
                            Option(Object([1], (0, 5)), -1993017406633284401),
                            Option(Object([1], (6, 5)), -8036724089052714593)
                        ]), -1731569779980110441)]),
                    3 => Either([
                        Option(Object([3], (0, 8)), 8357411015276601514),
                        Option(Object([3], (6, 8)), -6298199269447202670)
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
                        ]), -6290834605491577753)]),
                    3 => Either([
                        Option((-1, 0), -6298199269447202670),
                        Option((1, 0), 8357411015276601514)
                    ])
                )
            ),
            Dict(
                "spatial_objects|grouped|0" => Dict(
                    3 => Object([3], (7, 8)),
                    2 => Object([2], (5, 0))
                ),
                "spatial_objects|grouped|0|step" => Dict(3 => (4, 0), 2 => (4, 0)),
                "spatial_objects|grouped|0|first|splitted|first" => Dict(
                    3 => Either([
                        Option(Object([3], (7, 8)), 7545786358977917744),
                        Option(Object([3], (7, 0)), 5481204809736699004)
                    ]),
                    2 => Either([
                        Option(Object([2], (5, 8)), 2381155038609862840),
                        Option(Object([2], (5, 0)), -5875894171303851447)
                    ])
                ),
                "spatial_objects|grouped|0|first|splitted|step" => Dict(
                    3 => Either([
                        Option((0, -1), 7545786358977917744),
                        Option((0, 1), 5481204809736699004)
                    ]),
                    2 => Either([
                        Option((0, -1), 2381155038609862840),
                        Option((0, 1), -5875894171303851447)
                    ])
                )
            ),
            Dict(
                "spatial_objects|grouped|0" => Dict(
                    4 => Object([4], (7, 0)),
                    1 => Object([1], (11, 0))
                ),
                "spatial_objects|grouped|0|step" => Dict(
                    4 => Either([
                        Option((8, 0), -5805011747554057236),
                        Option((-8, 0), -4442776895041541795)
                    ]),
                    1 => (8, 0)
                ),
                "spatial_objects|grouped|0|first|splitted|first" => Dict(
                    4 => Either([
                        Option(Either([
                            Option(Object([4], (23, 0)), -7517451788434914494),
                            Option(Object([4], (23, 7)), 6114323803394542134)
                        ]), -4442776895041541795),
                        Option(Either([
                            Option(Object([4], (7, 0)), 474248072841930054),
                            Option(Object([4], (7, 7)), 769968888881597735)
                        ]), -5805011747554057236)]),
                    1 => Either([
                        Option(Object([1], (11, 7)), 6149872379558691894),
                        Option(Object([1], (11, 0)), 5497714720948989413)
                    ])
                ),
                "spatial_objects|grouped|0|first|splitted|step" => Dict(
                    4 => Either([
                        Option(Either([
                            Option((0, -1), 769968888881597735),
                            Option((0, 1), 474248072841930054)
                        ]), -5805011747554057236),
                        Option(Either([
                            Option((0, -1), 6114323803394542134),
                            Option((0, 1), -7517451788434914494)
                        ]), -4442776895041541795)]),
                    1 => Either([
                        Option((0, -1), 6149872379558691894),
                        Option((0, 1), 5497714720948989413)
                    ])
                )
            )
        ], ["spatial_objects|grouped|0|first|splitted|first"])
        new_solutions = match_fields(solution)
        @test length(new_solutions) == 1
        new_solution = new_solutions[1]
        @test new_solution.blocks[end].operations == [
            CopyParam("spatial_objects|grouped|0|first|splitted|first", "spatial_objects|grouped|0")
        ]
        @test filtered_taskdata(new_solution) == [
            Dict(
                "spatial_objects|grouped|0" => Dict(
                    8 => Object([8], (9, 7)),
                    2 => Object([2], (0, 5))
                ),
                "spatial_objects|grouped|0|step" => Dict(2 => (0, 4), 8 => (0, 4)),
                "spatial_objects|grouped|0|first|splitted|first" => Dict(
                    2 => Object([2], (0, 5)),
                    8 => Object([8], (9, 7)),
                ),
                "spatial_objects|grouped|0|first|splitted|step" => Dict(
                    2 => (1, 0),
                    8 => (-1, 0),
                )
            ),
            Dict(
                "spatial_objects|grouped|0" => Dict(
                    3 => Object([3], (6, 8)),
                    1 => Object([1], (0, 5))
                ),
                "spatial_objects|grouped|0|step" => Dict(
                    1 => (0, 6),
                    3 => (0, 6)
                ),
                "spatial_objects|grouped|0|first|splitted|first" => Dict(
                    1 => Object([1], (0, 5)),
                    3 => Object([3], (6, 8)),
                ),
                "spatial_objects|grouped|0|first|splitted|step" => Dict(
                    1 => (1, 0),
                    3 => (-1, 0),
                )
            ),
            Dict(
                "spatial_objects|grouped|0" => Dict(
                    3 => Object([3], (7, 8)),
                    2 => Object([2], (5, 0))
                ),
                "spatial_objects|grouped|0|step" => Dict(3 => (4, 0), 2 => (4, 0)),
                "spatial_objects|grouped|0|first|splitted|first" => Dict(
                    3 => Object([3], (7, 8)),
                    2 => Object([2], (5, 0)),
                ),
                "spatial_objects|grouped|0|first|splitted|step" => Dict(
                    3 => (0, -1),
                    2 => (0, 1),
                )
            ),
            Dict(
                "spatial_objects|grouped|0" => Dict(
                    4 => Object([4], (7, 0)),
                    1 => Object([1], (11, 0))
                ),
                "spatial_objects|grouped|0|step" => Dict(
                    4 => (8, 0),
                    1 => (8, 0)
                ),
                "spatial_objects|grouped|0|first|splitted|first" => Dict(
                    4 => Object([4], (7, 0)),
                    1 => Object([1], (11, 0)),
                ),
                "spatial_objects|grouped|0|first|splitted|step" => Dict(
                    4 => (0, 1),
                    1 => (0, 1),
                )
            )
        ]

        @test filtered_taskdata(solution) == [
            Dict(
                "spatial_objects|grouped|0" => Dict(
                    8 => Object([8], (9, 7)),
                    2 => Object([2], (0, 5))
                ),
                "spatial_objects|grouped|0|step" => Dict(2 => (0, 4), 8 => (0, 4)),
                "spatial_objects|grouped|0|first|splitted|first" => Dict(
                    2 => Either([
                        Option(
                            Object([2], (0, 5)),
                            -8357220665304833330),
                        Option(
                            Object([2], (9, 5)),
                            -7774447106926069087)
                    ]),
                    8 => Either([
                        Option(
                            Object([8], (9, 7)),
                            -7449978942198423200
                        ),
                        Option(
                            Object([8], (0, 7)),
                            -556451181567613247)
                    ])
                ),
                "spatial_objects|grouped|0|first|splitted|step" => Dict(
                    2 => Either([
                        Option((-1, 0), -7774447106926069087),
                        Option((1, 0), -8357220665304833330)
                    ]),
                    8 => Either([
                        Option((-1, 0), -7449978942198423200),
                        Option((1, 0), -556451181567613247)
                    ])
                )
            ),
            Dict(
                "spatial_objects|grouped|0" => Dict(
                    3 => Object([3], (6, 8)),
                    1 => Object([1], (0, 5))
                ),
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
                            Option(Object([1], (0, 17)), -987741356063359383),
                            Option(Object([1], (6, 17)), 5337975097275602430)
                        ]), -6290834605491577753),
                        Option(Either([
                            Option(Object([1], (0, 5)), -1993017406633284401),
                            Option(Object([1], (6, 5)), -8036724089052714593)
                        ]), -1731569779980110441)]),
                    3 => Either([
                        Option(Object([3], (0, 8)), 8357411015276601514),
                        Option(Object([3], (6, 8)), -6298199269447202670)
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
                        ]), -6290834605491577753)]),
                    3 => Either([
                        Option((-1, 0), -6298199269447202670),
                        Option((1, 0), 8357411015276601514)
                    ])
                )
            ),
            Dict(
                "spatial_objects|grouped|0" => Dict(
                    3 => Object([3], (7, 8)),
                    2 => Object([2], (5, 0))
                ),
                "spatial_objects|grouped|0|step" => Dict(3 => (4, 0), 2 => (4, 0)),
                "spatial_objects|grouped|0|first|splitted|first" => Dict(
                    3 => Either([
                        Option(Object([3], (7, 8)), 7545786358977917744),
                        Option(Object([3], (7, 0)), 5481204809736699004)
                    ]),
                    2 => Either([
                        Option(Object([2], (5, 8)), 2381155038609862840),
                        Option(Object([2], (5, 0)), -5875894171303851447)
                    ])
                ),
                "spatial_objects|grouped|0|first|splitted|step" => Dict(
                    3 => Either([
                        Option((0, -1), 7545786358977917744),
                        Option((0, 1), 5481204809736699004)
                    ]),
                    2 => Either([
                        Option((0, -1), 2381155038609862840),
                        Option((0, 1), -5875894171303851447)
                    ])
                )
            ),
            Dict(
                "spatial_objects|grouped|0" => Dict(
                    4 => Object([4], (7, 0)),
                    1 => Object([1], (11, 0))
                ),
                "spatial_objects|grouped|0|step" => Dict(
                    4 => Either([
                        Option((8, 0), -5805011747554057236),
                        Option((-8, 0), -4442776895041541795)
                    ]),
                    1 => (8, 0)
                ),
                "spatial_objects|grouped|0|first|splitted|first" => Dict(
                    4 => Either([
                        Option(Either([
                            Option(Object([4], (23, 0)), -7517451788434914494),
                            Option(Object([4], (23, 7)), 6114323803394542134)
                        ]), -4442776895041541795),
                        Option(Either([
                            Option(Object([4], (7, 0)), 474248072841930054),
                            Option(Object([4], (7, 7)), 769968888881597735)
                        ]), -5805011747554057236)]),
                    1 => Either([
                        Option(Object([1], (11, 7)), 6149872379558691894),
                        Option(Object([1], (11, 0)), 5497714720948989413)
                    ])
                ),
                "spatial_objects|grouped|0|first|splitted|step" => Dict(
                    4 => Either([
                        Option(Either([
                            Option((0, -1), 769968888881597735),
                            Option((0, 1), 474248072841930054)
                        ]), -5805011747554057236),
                        Option(Either([
                            Option((0, -1), 6114323803394542134),
                            Option((0, 1), -7517451788434914494)
                        ]), -4442776895041541795)]),
                    1 => Either([
                        Option((0, -1), 6149872379558691894),
                        Option((0, 1), 5497714720948989413)
                    ])
                )
            )
        ]
    end
end
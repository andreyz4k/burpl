
using .PatternMatching:Either,Option,ObjectShape
using .DataTransformers:find_const,SetConst,CopyParam,find_dependent_key,
MultParam,MultByParam,IncParam,IncByParam,MapValues,match_fields,DecByParam
using .ObjectPrior:Object
using .Abstractors:SelectGroup,Abstractor
using .Solutions:FieldInfo

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

        @test find_const(taskdata, Dict("background" => FieldInfo(1, "input", [], [Set()])), [], "background") == [SetConst("background", 1)]

        taskdata = [
                Dict{String,Any}(
                    "background" => 1
                ),
                Dict{String,Any}(
                    "background" => Either([1, 2])
                )
            ]

        @test find_const(taskdata, Dict("background" => FieldInfo(1, "input", [], [Set()])), [], "background") == [SetConst("background", 1)]

        taskdata = [
                Dict{String,Any}(
                    "background" => Either([1, 2])
                ),
                Dict{String,Any}(
                    "background" => 1
                ),
            ]

        @test find_const(taskdata, Dict("background" => FieldInfo(1, "input", [], [Set()])), [], "background") == [SetConst("background", 1)]

        taskdata = [
                Dict{String,Any}(
                    "background" => Either([1, 2])
                ),
                Dict{String,Any}(
                    "background" => Either([1, 3])
                ),
            ]

        @test find_const(taskdata, Dict("background" => FieldInfo(1, "input", [], [Set()])), [], "background") == [SetConst("background", 1)]

        taskdata = [
                Dict{String,Any}(
                    "background" => Either([1, 2])
                ),
                Dict{String,Any}(
                    "background" => Either([1, 2])
                ),
            ]

        @test issetequal(find_const(taskdata, Dict("background" => FieldInfo(1, "input", [], [Set()])), [], "background"), [SetConst("background", 1), SetConst("background", 2)])
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
        @test find_const(taskdata, Dict("key" => FieldInfo(1, "input", [], [Set()])), [], "key") == [SetConst("key", Dict(2 => 2, 1 => 1))]

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
        @test find_const(taskdata, Dict("key" => FieldInfo(1, "input", [], [Set()])), [], "key") == [SetConst("key", Dict(
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
        @test filtered_ops(new_solution) == [SetConst("background", 1)]
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
        @test length(new_solutions) == 3
        expected_operations = Set([
            [SetConst("key1", 1), SetConst("key2", 2)],
            [SetConst("key2", 4)],
            [SetConst("key2", 2), IncParam("key1", "key2", -1)]
        ])
        
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
        @test filtered_taskdata(new_solutions[2]) == [
            Dict(
                "key2" => 2,
                "key1" => 1,
                "key1|inc_shift" => -1
            ),
            Dict(
                "key2" => 2, 
                "key1" => 1, 
                "key1|inc_shift" => -1
            )
        ]
        @test filtered_taskdata(new_solutions[3]) == [
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
        @test filtered_ops(new_solutions[1]) == [CopyParam("key1", "key3")]
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
        ], ["spatial_objects|grouped|0|first|splitted|first", "spatial_objects|grouped|0|first|splitted|step", "spatial_objects|grouped|0|step"])
        new_solutions = match_fields(solution)
        @test length(new_solutions) == 1
        new_solution = new_solutions[1]
        @test filtered_ops(new_solution) == [
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

    @testset "match nothing" begin
        taskdata = [
            Dict{String,Any}(
                "key_none" => nothing,
                "key" => 1
            ),
            Dict{String,Any}(
                "key_none" => nothing,
                "key" => 2
            )
        ]
        @test find_dependent_key(taskdata, Dict("key" => FieldInfo(1, "input", [], [Set()]), "key_none" => FieldInfo(nothing, "input", [], [Set()])), Set(["key"]), "key") == []
    end

    @testset "find multiply" begin
        solution = make_dummy_solution([
            Dict(
                "key" => 15,
                "key1" => 5,
                "key2" => 2
            ),
            Dict(
                "key" => 18,
                "key1" => 6,
                "key2" => 2
            )
        ],["key"])
        new_solutions = match_fields(solution)
        @test length(new_solutions) == 1
        expected_operations = Set([
            [MultParam("key", "key1", 3)],
        ])
        _compare_operations(expected_operations, new_solutions)

        solution = make_dummy_solution([
            Dict(
                "output|bgr_grid|grid|spatial_objects|grouped|step|to_value" => (4, 0),
                "projected|output|bgr_grid|grid|spatial_objects|distance" => (-2, 0),
            ),
            Dict(
                "output|bgr_grid|grid|spatial_objects|grouped|step|to_value" => (6, 0),
                "projected|output|bgr_grid|grid|spatial_objects|distance" => (-3, 0)
            ),
            Dict(
                "output|bgr_grid|grid|spatial_objects|grouped|step|to_value" => (0, 4),
                "projected|output|bgr_grid|grid|spatial_objects|distance" => (0, -2)
            ),
            Dict(
                "output|bgr_grid|grid|spatial_objects|grouped|step|to_value" => (0, 8),
                "projected|output|bgr_grid|grid|spatial_objects|distance" => (0, -4)
            )
        ], ["output|bgr_grid|grid|spatial_objects|grouped|step|to_value"])
        new_solutions = match_fields(solution)
        @test length(new_solutions) == 1
        expected_operations = Set([
            [MultParam("output|bgr_grid|grid|spatial_objects|grouped|step|to_value", "projected|output|bgr_grid|grid|spatial_objects|distance", -2)],
        ])
        _compare_operations(expected_operations, new_solutions)
    end

    @testset "find multiply by key" begin
        solution = make_dummy_solution([
            Dict(
                "key" => 10,
                "key1" => 5,
                "key2" => 2
            ),
            Dict(
                "key" => 12,
                "key1" => 4,
                "key2" => 3
            )
        ], ["key"])
        new_solutions = match_fields(solution)
        @test length(new_solutions) == 2
        expected_operations = Set([
            [MultByParam("key", "key1", "key2")],
            [MultByParam("key", "key2", "key1")],
        ])
        _compare_operations(expected_operations, new_solutions)
    end

    @testset "find shift" begin
        solution = make_dummy_solution([
            Dict(
                "key" => 10,
                "key1" => 5,
                "key2" => 2
            ),
            Dict(
                "key" => 12,
                "key1" => 7,
                "key2" => 2
            )
        ], ["key"])
        new_solutions = match_fields(solution)
        @test length(new_solutions) == 1
        expected_operations = Set([
            [IncParam("key", "key1", 5)],
        ])
        _compare_operations(expected_operations, new_solutions)
    end

    @testset "find shifted tuple list" begin
        solution = make_dummy_solution([
            Dict(
                "input|bgr_grid|grid|spatial_objects|grouped|positions|selected_by|output|grid|bgr_grid|spatial_objects|shapes|selected_group" => [(1, 13), (1, 12), (7, 17), (9, 17)],
                "input|bgr_grid|grid_size" => (21, 21),
                "output|grid_size" => (10, 10),
                "input|background" => 0,
                "output|grid|bgr_grid|spatial_objects|positions" => [(1, 2), (1, 1), (7, 6), (9, 6)],
            ),
            Dict(
                "input|bgr_grid|grid|spatial_objects|grouped|positions|selected_by|output|grid|bgr_grid|spatial_objects|shapes|selected_group" => [(11, 12), (12, 17), (15, 14), (15, 12), (18, 18)],
                "input|bgr_grid|grid_size" => (19, 18),
                "output|grid_size" => (9, 7),
                "input|background" => 0,
                "output|grid|bgr_grid|spatial_objects|positions" => [(1, 1), (2, 6), (5, 3), (5, 1), (8, 7)],
            ),
            Dict(
                "input|bgr_grid|grid|spatial_objects|grouped|positions|selected_by|output|grid|bgr_grid|spatial_objects|shapes|selected_group" => [(1, 11), (4, 19), (6, 11), (6, 17), (6, 19)],
                "input|bgr_grid|grid_size" => (17, 19),
                "output|grid_size" => (6, 9),
                "input|background" => 0,
                "output|grid|bgr_grid|spatial_objects|positions" => [(1, 1), (4, 9), (6, 1), (6, 7), (6, 9)],
            )
        ], ["output|grid|bgr_grid|spatial_objects|positions"])
        # new_solutions = match_fields(solution)
        # @test length(new_solutions) == 1
        # expected_operations = Set([
        #     [IncByParam("key", "key1", "key2")],
        #     [IncByParam("key", "key2", "key1")],
        # ])
        # _compare_operations(expected_operations, new_solutions)
    end

    @testset "find shift by key" begin
        solution = make_dummy_solution([
            Dict(
                "key" => 10,
                "key1" => 7,
                "key2" => 3
            ),
            Dict(
                "key" => 12,
                "key1" => 8,
                "key2" => 4
            )
        ],["key"])
        new_solutions = match_fields(solution)
        @test length(new_solutions) == 2
        expected_operations = Set([
            [IncByParam("key", "key1", "key2")],
            [IncByParam("key", "key2", "key1")],
        ])
        _compare_operations(expected_operations, new_solutions)
    end

    @testset "find no shift with zero values" begin
        solution = make_dummy_solution([
            Dict(
                "key" => 10,
                "key1" => 10,
                "key3" => 10,
                "key2" => 0
            ),
            Dict(
                "key" => 12,
                "key1" => 12,
                "key3" => 12,
                "key2" => 0
            )
        ],["key"])
        new_solutions = match_fields(solution)
        @test length(new_solutions) == 2
        expected_operations = Set([
            [CopyParam("key", "key1")],
            [CopyParam("key", "key3")],
        ])
        _compare_operations(expected_operations, new_solutions)
    end

    @testset "find matching group" begin
        solution = make_dummy_solution([
            Dict(
                "input|bgr_grid|grid|spatial_objects|grouped" => Dict{Int64,Array{Main.Randy.ObjectPrior.Object,1}}(
                    2 => [
                        Object([2], (1, 13)),
                        Object([-1 -1 -1 2 2 2 2 -1 2 2; 2 -1 2 2 2 2 2 2 2 -1; 2 2 2 2 2 2 -1 2 2 2; 2 2 2 2 2 2 2 -1 2 2; -1 2 2 -1 2 2 2 -1 2 -1; -1 -1 2 2 2 -1 -1 2 2 2; 2 -1 2 2 -1 -1 -1 2 2 2; 2 2 -1 2 2 -1 -1 -1 2 2; 2 2 2 2 -1 -1 -1 -1 2 2; 2 2 -1 2 -1 -1 -1 2 2 2], (1, 12)),
                        Object([2], (7, 17)),
                        Object([2; 2], (9, 17))
                    ],
                    8 => [
                        Object([8 8 8 8 8 -1 8 8 8; 8 -1 8 8 8 -1 8 -1 8; 8 -1 8 -1 8 -1 8 -1 8; 8 8 -1 8 8 8 8 8 8; 8 -1 -1 8 -1 8 -1 -1 8; -1 -1 -1 8 8 -1 -1 -1 8; 8 -1 8 8 8 8 8 8 -1; 8 8 8 -1 -1 -1 -1 8 8; 8 8 8 8 8 -1 -1 -1 -1; 8 8 8 8 8 8 -1 -1 -1], (1, 1)),
                        Object([8], (6, 2)),
                        Object([8], (9, 7)),
                        Object([8], (10, 8)),
                        Object([8 8 8 8 8 8 8 8 8; 8 8 8 8 8 -1 8 -1 8; 8 8 -1 -1 8 -1 8 8 8; 8 -1 8 -1 -1 -1 -1 8 8; -1 -1 8 -1 8 8 8 8 8; 8 -1 8 8 8 -1 8 8 -1; 8 8 8 8 8 -1 8 8 -1], (15, 1)),
                        Object([8 8 8 8 8 8 8 8; 8 8 8 8 8 -1 8 -1; -1 8 8 -1 8 8 -1 -1; 8 8 -1 8 8 -1 -1 -1; 8 -1 -1 8 8 8 -1 -1; -1 -1 -1 8 -1 8 -1 -1; -1 -1 -1 -1 -1 8 8 -1], (15, 12)),
                        Object([-1 8; 8 8; 8 8], (15, 20)),
                        Object([8], (18, 18)),
                        Object([8 -1 8; 8 8 8; -1 8 8], (19, 19)),
                        Object([8], (20, 13)),
                        Object([8], (21, 12)),
                        Object([8], (21, 14))
                    ]
                ),
                "output|grid|bgr_grid|spatial_objects|shapes" => ObjectShape{Object}[
                    ObjectShape(Object([2], (1, 2))),
                    ObjectShape(Object([-1 -1 -1 2 2 2 2 -1 2 2; 2 -1 2 2 2 2 2 2 2 -1; 2 2 2 2 2 2 -1 2 2 2; 2 2 2 2 2 2 2 -1 2 2; -1 2 2 -1 2 2 2 -1 2 -1; -1 -1 2 2 2 -1 -1 2 2 2; 2 -1 2 2 -1 -1 -1 2 2 2; 2 2 -1 2 2 -1 -1 -1 2 2; 2 2 2 2 -1 -1 -1 -1 2 2; 2 2 -1 2 -1 -1 -1 2 2 2], (1, 1))),
                    ObjectShape(Object([2], (7, 6))),
                    ObjectShape(Object([2; 2], (9, 6)))
                ],
                "input|bgr_grid|grid_size" => (21, 21),
                "output|grid_size" => (10, 10),
                "input|background" => 0,
                "output|grid|bgr_grid|spatial_objects|positions" => [(1, 2), (1, 1), (7, 6), (9, 6)],
                "input|bgr_grid|grid|spatial_objects|group_keys" => [2, 8],
                "output" => [1 2; 3 4]
            ),
            Dict(
                "input|bgr_grid|grid|spatial_objects|grouped" => Dict{Int64,Array{Main.Randy.ObjectPrior.Object,1}}(
                    2 => [
                        Object([2 2 -1 -1 -1 -1; -1 2 -1 -1 -1 -1; 2 2 2 2 -1 -1; 2 2 2 -1 2 -1; 2 -1 -1 2 2 2; 2 2 2 2 2 -1; -1 2 -1 -1 2 2], (1, 1)),
                        Object([2], (1, 4)),
                        Object([-1 2; 2 2; -1 2], (1, 5)),
                        Object([2], (1, 12)),
                        Object([-1 -1 -1 2 2 2; -1 2 2 2 -1 -1; 2 2 2 2 -1 -1], (1, 12)),
                        Object([-1 2; 2 2], (2, 17)),
                        Object([-1 -1 -1 -1 2; -1 -1 -1 -1 2; -1 2 2 2 2; 2 2 -1 2 -1], (4, 12)),
                        Object([2; 2], (5, 18)),
                        Object([2], (7, 17)),
                        Object([2], (11, 1)),
                        Object([-1 -1 2 -1 -1 -1; -1 2 2 2 -1 -1; 2 2 2 2 -1 2; 2 2 -1 2 2 2; 2 2 2 2 2 2; 2 2 2 2 -1 2; -1 -1 2 2 2 -1; -1 -1 2 -1 2 2; -1 -1 2 -1 2 -1], (11, 1)),
                        Object([2], (11, 6)),
                        Object([2], (19, 1))
                    ],
                    3 => [
                        Object([-1 3 3 3 3; 3 3 3 3 -1; 3 3 3 -1 -1; 3 -1 -1 -1 -1; 3 -1 -1 -1 -1; 3 -1 -1 -1 -1], (11, 12)),
                        Object([3 3; 3 3], (12, 17)),
                        Object([3], (15, 14)),
                        Object([-1 -1 -1 -1 3 3 -1; -1 -1 -1 3 -1 3 3; -1 3 3 3 3 3 -1; 3 3 -1 3 -1 -1 -1; 3 -1 -1 3 3 3 -1], (15, 12)),
                        Object([3], (18, 18))
                    ]
                ),
                "output|grid|bgr_grid|spatial_objects|shapes" => ObjectShape{Object}[
                    ObjectShape(Object([-1 3 3 3 3; 3 3 3 3 -1; 3 3 3 -1 -1; 3 -1 -1 -1 -1; 3 -1 -1 -1 -1; 3 -1 -1 -1 -1], (1, 1))),
                    ObjectShape(Object([3 3; 3 3], (2, 6))),
                    ObjectShape(Object([3], (5, 3))),
                    ObjectShape(Object([-1 -1 -1 -1 3 3 -1; -1 -1 -1 3 -1 3 3; -1 3 3 3 3 3 -1; 3 3 -1 3 -1 -1 -1; 3 -1 -1 3 3 3 -1], (5, 1))),
                    ObjectShape(Object([3], (8, 7)))
                ],
                "input|bgr_grid|grid_size" => (19, 18),
                "output|grid_size" => (9, 7),
                "input|background" => 0,
                "output|grid|bgr_grid|spatial_objects|positions" => [(1, 1), (2, 6), (5, 3), (5, 1), (8, 7)],
                "input|bgr_grid|grid|spatial_objects|group_keys" => [2, 3],
                "output" => [2 3; 4 5]
            ),
            Dict(
                "input|bgr_grid|grid|spatial_objects|grouped" => Dict{Int64,Array{Main.Randy.ObjectPrior.Object,1}}(
                    4 => [
                        Object([4 4 4 -1 4 -1 -1 -1 4; -1 4 -1 4 4 4 4 4 4; -1 4 4 4 4 4 4 -1 -1; 4 4 -1 4 -1 4 4 -1 -1; -1 -1 -1 4 4 4 -1 -1 -1; -1 -1 -1 -1 4 -1 -1 -1 -1], (1, 11)),
                        Object([4], (4, 19)),
                        Object([4 4 4], (6, 11)),
                        Object([4], (6, 17)),
                        Object([4], (6, 19))
                    ],
                    1 => [
                        Object([1 1 1 -1 -1 -1; -1 1 1 1 -1 -1; -1 -1 -1 1 -1 -1; -1 -1 -1 1 1 1; -1 -1 -1 -1 -1 1], (1, 2)),
                        Object([1], (1, 6)),
                        Object([1], (2, 1)),
                        Object([1], (3, 2)),
                        Object([1; 1; 1], (4, 1)),
                        Object([1 -1; 1 1; -1 1], (4, 3)),
                        Object([1 1 1 1 1 1 1; 1 1 1 1 1 1 1; -1 1 1 -1 -1 -1 1; 1 1 1 1 -1 -1 -1; -1 1 1 1 -1 1 -1; -1 1 1 1 1 1 1; -1 -1 -1 1 1 1 -1; -1 1 1 1 1 1 -1; -1 1 1 1 -1 1 1], (9, 1)),
                        Object([1 1], (9, 11)),
                        Object([-1 -1 -1 1 1 -1 -1 -1 -1; -1 -1 1 1 1 1 1 -1 -1; -1 1 -1 -1 1 -1 -1 -1 -1; 1 1 -1 -1 1 -1 -1 -1 -1; 1 1 1 1 1 -1 -1 -1 -1; 1 1 1 -1 1 -1 1 -1 1; 1 1 1 1 1 1 1 1 1; 1 1 1 -1 1 1 1 -1 1; 1 -1 1 1 -1 1 -1 -1 -1], (9, 11)),
                        Object([-1 1 1; -1 -1 1; -1 1 1; 1 1 -1; -1 1 -1], (9, 17)),
                        Object([1], (17, 18))
                    ]
                ),
                "output|grid|bgr_grid|spatial_objects|shapes" => ObjectShape{Object}[
                    ObjectShape(Object([4 4 4 -1 4 -1 -1 -1 4; -1 4 -1 4 4 4 4 4 4; -1 4 4 4 4 4 4 -1 -1; 4 4 -1 4 -1 4 4 -1 -1; -1 -1 -1 4 4 4 -1 -1 -1; -1 -1 -1 -1 4 -1 -1 -1 -1], (1, 1))),
                    ObjectShape(Object([4], (4, 9))),
                    ObjectShape(Object([4 4 4], (6, 1))),
                    ObjectShape(Object([4], (6, 7))),
                    ObjectShape(Object([4], (6, 9)))
                ],
                "input|bgr_grid|grid_size" => (17, 19),
                "output|grid_size" => (6, 9),
                "input|background" => 0,
                "output|grid|bgr_grid|spatial_objects|positions" => [(1, 1), (4, 9), (6, 1), (6, 7), (6, 9)],
                "input|bgr_grid|grid|spatial_objects|group_keys" => [1, 4],
                "output" => [3 4; 5 6]
            )
        ], ["output|grid|bgr_grid|spatial_objects|shapes", "output|grid_size", "output|grid|bgr_grid|spatial_objects|positions"])
        new_solutions = match_fields(solution)
        @test length(new_solutions) == 1
        new_solution = new_solutions[1]
        @test filtered_ops(new_solution) == [
            Abstractor(SelectGroup(), true,
                       ["input|bgr_grid|grid|spatial_objects|grouped", "output|grid|bgr_grid|spatial_objects|shapes|selected_group"],
                       ["output|grid|bgr_grid|spatial_objects|shapes", "output|grid|bgr_grid|spatial_objects|shapes|rejected"], String[])
        ]
    end

    @testset "match dec by param" begin
        solution = make_dummy_solution([
            Dict(
                "input|bgr_grid|spatial_objects|positions" => [(2, 12), (5, 14), (10, 12)],
                "input|bgr_grid|spatial_objects|obj_size|coord2" => [(0, 4), (0, 2), (0, 4)],
                "output|grid|bgr_grid|spatial_objects|positions" => [(2, 8), (5, 12), (10, 8)],
            ),
            Dict(
                "input|bgr_grid|spatial_objects|positions" => [(2, 10), (8, 14), (12, 11)],
                "input|bgr_grid|spatial_objects|obj_size|coord2" => [(0, 6), (0, 2), (0, 5)],
                "output|grid|bgr_grid|spatial_objects|positions" => [(2, 4), (8, 12), (12, 6)],
            ),
            Dict(
                "input|bgr_grid|spatial_objects|positions" => [(2, 15), (8, 12), (12, 13)],
                "input|bgr_grid|spatial_objects|obj_size|coord2" => [(0, 1), (0, 4), (0, 3)],
                "output|grid|bgr_grid|spatial_objects|positions" => [(2, 14), (8, 8), (12, 10)],
            )
        ],["output|grid|bgr_grid|spatial_objects|positions"])
        new_solutions = match_fields(solution)
        @test length(new_solutions) == 1
        expected_operations = Set([
            [DecByParam("output|grid|bgr_grid|spatial_objects|positions", "input|bgr_grid|spatial_objects|positions", "input|bgr_grid|spatial_objects|obj_size|coord2")],
        ])
        _compare_operations(expected_operations, new_solutions)
    end
end

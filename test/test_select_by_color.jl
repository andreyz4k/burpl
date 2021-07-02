
# using .Abstractors:SelectColor


@testset "Select Objects by color" begin
    return
    @testset "select objects" begin
        selector = SelectColor("key", "selector_key", true)
        input_data = Dict(
            "key" => [Object([0 0], (1, 1)), Object([0; 0], (3, 2)), Object([1], (4, 1)), Object([2], (1, 5))],
            "selector_key" => 0,
        )
        output_data = selector([], [], input_data)[2]
        @test output_data == Dict(
            "key" => [Object([0 0], (1, 1)), Object([0; 0], (3, 2)), Object([1], (4, 1)), Object([2], (1, 5))],
            "selector_key" => 0,
            "key|selected_by_color|selector_key" => [Object([0 0], (1, 1)), Object([0; 0], (3, 2))],
            "key|rejected_by_color|selector_key" => [Object([1], (4, 1)), Object([2], (1, 5))],
        )
        delete!(output_data, "key")
        selector = SelectColor("key", "selector_key", false)
        reverted_data = selector([], [], output_data)[2]
        @test reverted_data["key"] == input_data["key"]
    end

    @testset "create selector" begin
        solution = make_dummy_solution([
            Dict(
                "input|key" =>
                    [Object([0 0], (1, 1)), Object([0; 0], (3, 2)), Object([1], (4, 1)), Object([2], (1, 5))],
                "input|selector_key" => 0,
            ),
            Dict(
                "input|key" =>
                    [Object([0 0], (1, 1)), Object([0; 0], (3, 2)), Object([1], (4, 1)), Object([2], (1, 5))],
                "input|selector_key" => 0,
            ),
        ])
        abstractors = create(SelectColor(), solution, "input|key")
        @test length(abstractors) == 1
        priority, abstractor = abstractors[1]
        @test priority == 2.3
        @test abstractor.to_abstract == SelectColor("input|key", "input|selector_key", true)
        @test abstractor.to_abstract.input_keys == ["input|key", "input|selector_key"]
        @test abstractor.to_abstract.output_keys ==
              ["input|key|selected_by_color|input|selector_key", "input|key|rejected_by_color|input|selector_key"]
        @test abstractor.from_abstract == SelectColor("input|key", "input|selector_key", false)
        @test abstractor.from_abstract.input_keys ==
              ["input|key|selected_by_color|input|selector_key", "input|key|rejected_by_color|input|selector_key"]
        @test abstractor.from_abstract.output_keys == ["input|key"]
    end
end


using .ObjectPrior: Object
using .Abstractors: CountObjects, UniteTouching, UnwrapSingleList
using .PatternMatching: ObjectsGroup, SubSet, ObjectShape

@testset "Matcher persistance" begin
    @testset "Shape persistance" begin
        taskdata = make_taskdata(
            Dict(
                "output|bgr_grid|spatial_objects|shape" => ObjectsGroup(
                    Set(
                        Object[
                            Object([8], (3, 1)),
                            Object([8], (1, 1)),
                            Object([8], (3, 3)),
                            Object([8], (1, 3)),
                            Object([8], (2, 2)),
                        ],
                    ),
                ),
            ),
        )
        op = CountObjects("output|bgr_grid|spatial_objects|shape", true)
        out_data = op(taskdata)
        @test out_data["output|bgr_grid|spatial_objects|shape|counted"] == ObjectsGroup(
            SubSet{Set{Object}}(
                Set{Object}[Set([
                    Object([8], (3, 1)),
                    Object([8], (1, 1)),
                    Object([8], (3, 3)),
                    Object([8], (1, 3)),
                    Object([8], (2, 2)),
                ])],
            ),
        )
        op = UniteTouching("output|bgr_grid|spatial_objects|shape|counted", true)
        out_data2 = op(out_data)
        @test out_data2["output|bgr_grid|spatial_objects|shape|counted|united_touch"] ==
              ObjectsGroup(SubSet{Set{Object}}(Set{Object}[Set([Object([8 -1 8; -1 8 -1; 8 -1 8], (1, 1))])]))
        op = UnwrapSingleList("output|bgr_grid|spatial_objects|shape|counted|united_touch", true)
        out_data3 = op(out_data2)
        @test out_data3["output|bgr_grid|spatial_objects|shape|counted|united_touch|single_value"] ==
              ObjectShape(Object([8 -1 8; -1 8 -1; 8 -1 8], (1, 1)))
    end
end


using .Abstractors:GridSize,BackgroundColor,Transpose,SolidObjects,CountObjects,GroupObjectsByColor,
    RepeatObjectInfinite,DotProductClass,UnwrapSingleList,AlignedWithBorder,DistanceBetweenObjects,RemoveRedundantDict,
    GetPosition,GroupMin,MinPadding

@testset "Check ideal solutions" begin
    @testset "ff28f65a" begin
        fname = "../data/training/ff28f65a.json"
        taskdata = Randy.get_taskdata(fname)
        operations = [
            (GridSize(), "output", false),
            (BackgroundColor(), "output|grid", false),
            (BackgroundColor(), "input", true),
            (Transpose(), "output|grid|bgr_grid", false),
            (SolidObjects(), "output|grid|bgr_grid|transposed", false),
            (SolidObjects(), "input|bgr_grid", true),
            (CountObjects(), "output|grid|bgr_grid|transposed|spatial_objects", false),
            (CountObjects(), "input|bgr_grid|spatial_objects", true),
        ]
        solution = create_solution(taskdata["train"], operations)
        @test Randy.test_solution(solution, fname) == (0, 0)
    end

    @testset "0a938d79" begin
        fname = "../data/training/0a938d79.json"
        taskdata = Randy.get_taskdata(fname)
        operations = [
            (GridSize(), "output", false),
            (GridSize(), "input", true),
            (BackgroundColor(), "output|grid", false),
            (BackgroundColor(), "input|grid", true),
            (SolidObjects(), "output|grid|bgr_grid", false),
            (SolidObjects(), "input|grid|bgr_grid", true),
            (GroupObjectsByColor(), "output|grid|bgr_grid|spatial_objects", false),
            (RepeatObjectInfinite(), "output|grid|bgr_grid|spatial_objects|grouped", false),
            (GroupObjectsByColor(), "input|grid|bgr_grid|spatial_objects", true),
            (DotProductClass(), "output|grid|bgr_grid|spatial_objects|grouped|first", false),
            (UnwrapSingleList(), "input|grid|bgr_grid|spatial_objects|grouped", true),
            (AlignedWithBorder(), "input|grid|bgr_grid|spatial_objects|grouped|single_value", true),
            (DistanceBetweenObjects(), "projected|output|grid|bgr_grid|spatial_objects", true),
            (RemoveRedundantDict(), "output|grid|bgr_grid|spatial_objects|grouped|step", false),
        ]
        solution = create_solution(taskdata["train"], operations)
        @test Randy.test_solution(solution, fname) == (0, 0)
    end

    @testset "0b148d64" begin
        fname = "../data/training/0b148d64.json"
        taskdata = Randy.get_taskdata(fname)
        operations = [
            (GridSize(), "output", false),
            (BackgroundColor(), "output|grid", false),
            (BackgroundColor(), "input", true),
            (SolidObjects(), "output|grid|bgr_grid", false),
            (SolidObjects(), "input|bgr_grid", true),
            (GroupObjectsByColor(), "input|bgr_grid|spatial_objects", true),
            (GetPosition(), "output|grid|bgr_grid|spatial_objects", false),
            (CountObjects(), "input|bgr_grid|spatial_objects|grouped", true),
            (GroupMin(), "input|bgr_grid|spatial_objects|grouped|length", true),
            (GetPosition(), "output|grid|bgr_grid|spatial_objects|shapes", true),
            (MinPadding(), "output|grid|bgr_grid|spatial_objects|shapes|positions", true),
            (GridSize(), "output|grid", true),
        ]
        solution = create_solution(taskdata["train"], operations)
        @test Randy.test_solution(solution, fname) == (0, 0)
    end
end

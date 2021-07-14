
using .Abstractors:
    BackgroundColor,
    Transpose,
    SolidObjects,
    CountObjects,
    GroupObjectsByColor,
    RepeatObjectInfinite,
    DotProductClass,
    UnwrapSingleList,
    AlignedWithBorder,
    DistanceBetweenObjects,
    RemoveRedundantDict,
    GetPosition,
    GroupMin,
    MinPadding,
    UniteTouching,
    GroupMax,
    CompactSimilarObjects,
    GetSize,
    SeparateAxis,
    VerticalSymmetry,
    HorisontalSymmetry,
    UniteInRect

using .FindSolution: get_taskdef

@testset "Check ideal solutions" begin
    @testset "ff28f65a" begin
        fname = "../data/training/ff28f65a.json"
        task_info = get_taskdef(fname)
        operations = [
            (BackgroundColor(), "output", false),
            (BackgroundColor(), "input", true),
            (Transpose(), "output|bgr_grid", false),
            (SolidObjects(), "output|bgr_grid|transposed", false),
            (SolidObjects(), "input|bgr_grid", true),
            (CountObjects(), "output|bgr_grid|transposed|spatial_objects", false),
            (CountObjects(), "input|bgr_grid|spatial_objects", true),
        ]
        solution = create_solution(task_info["train"], operations)
        @test test_solution(solution, task_info["test"])
    end

    @testset "0a938d79" begin
        fname = "../data/training/0a938d79.json"
        task_info = get_taskdef(fname)
        operations = [
            (BackgroundColor(), "output", false),
            (BackgroundColor(), "input", true),
            (SolidObjects(), "output|bgr_grid", false),
            (SolidObjects(), "input|bgr_grid", true),
            (GroupObjectsByColor(), "output|bgr_grid|spatial_objects", false),
            (RepeatObjectInfinite(), "output|bgr_grid|spatial_objects|grouped", false),
            (GroupObjectsByColor(), "input|bgr_grid|spatial_objects", true),
            (DotProductClass(), "output|bgr_grid|spatial_objects|grouped|first", false),
            (UnwrapSingleList(), "input|bgr_grid|spatial_objects|grouped", true),
            (AlignedWithBorder(), "input|bgr_grid|spatial_objects|grouped|single_value", true),
            (RemoveRedundantDict(), "output|bgr_grid|spatial_objects|grouped|step", false),
            (DistanceBetweenObjects(), "projected|output|bgr_grid|spatial_objects", true),
        ]
        solution = create_solution(task_info["train"], operations)
        @test test_solution(solution, task_info["test"])
    end

    @testset "0b148d64" begin
        fname = "../data/training/0b148d64.json"
        task_info = get_taskdef(fname)
        operations = [
            (BackgroundColor(), "output", false),
            (BackgroundColor(), "input", true),
            (SolidObjects(), "output|bgr_grid", false),
            (SolidObjects(), "input|bgr_grid", true),
            (GroupObjectsByColor(), "input|bgr_grid|spatial_objects", true),
            (GetPosition(), "output|bgr_grid|spatial_objects", false),
            (CountObjects(), "input|bgr_grid|spatial_objects|grouped", true),
            (GroupMin(), "input|bgr_grid|spatial_objects|grouped|length", true),
        ]
        solution = create_solution(task_info["train"], operations)
        @test_broken test_solution(solution, task_info["test"])
    end

    @testset "39a8645d" begin
        fname = "../data/training/39a8645d.json"
        task_info = get_taskdef(fname)
        operations = [
            (BackgroundColor(), "output", false),
            (BackgroundColor(), "input", true),
            (SolidObjects(), "output|bgr_grid", false),
            (UniteTouching(), "output|bgr_grid|spatial_objects", false),
            (UnwrapSingleList(), "output|bgr_grid|spatial_objects|united_touch", false),
            (GetPosition(), "output|bgr_grid|spatial_objects|united_touch|single_value", false),
            (SolidObjects(), "input|bgr_grid", true),
            (GroupObjectsByColor(), "input|bgr_grid|spatial_objects", true),
            (UniteTouching(), "input|bgr_grid|spatial_objects|grouped", true),
            (CompactSimilarObjects(), "input|bgr_grid|spatial_objects|grouped|united_touch", true),
            (CountObjects(), "input|bgr_grid|spatial_objects|grouped|united_touch|positions", true),
            (GroupMax(), "input|bgr_grid|spatial_objects|grouped|united_touch|positions|length", true),
        ]
        solution = create_solution(task_info["train"], operations)
        @test test_solution(solution, task_info["test"])
    end

    @testset "39a8645d_transformed" begin
        fname = "../data/training/39a8645d.json"
        task_info = get_taskdef(fname)
        operations = [
            (BackgroundColor(), "output", false),
            (BackgroundColor(), "input", true),
            (SolidObjects(), "output|bgr_grid", false),
            (UniteTouching(), "output|bgr_grid|spatial_objects", false),
            (UnwrapSingleList(), "output|bgr_grid|spatial_objects|united_touch", false),
            (GetPosition(), "output|bgr_grid|spatial_objects|united_touch|single_value", false),
            (HorisontalSymmetry(), "output|bgr_grid|spatial_objects|united_touch|single_value|shape", false),
            (SolidObjects(), "input|bgr_grid", true),
            (GroupObjectsByColor(), "input|bgr_grid|spatial_objects", true),
            (UniteTouching(), "input|bgr_grid|spatial_objects|grouped", true),
            (CompactSimilarObjects(), "input|bgr_grid|spatial_objects|grouped|united_touch", true),
            (CountObjects(), "input|bgr_grid|spatial_objects|grouped|united_touch|positions", true),
            (GroupMax(), "input|bgr_grid|spatial_objects|grouped|united_touch|positions|length", true),
        ]
        solution = create_solution(task_info["train"], operations)
        @test test_solution(solution, task_info["test"])
    end

    @testset "5521c0d9" begin
        fname = "../data/training/5521c0d9.json"
        task_info = get_taskdef(fname)
        operations = [
            (BackgroundColor(), "output", false),
            (BackgroundColor(), "input", true),
            (SolidObjects(), "output|bgr_grid", false),
            (SolidObjects(), "input|bgr_grid", true),
            (GroupObjectsByColor(), "output|bgr_grid|spatial_objects", false),
            (GroupObjectsByColor(), "input|bgr_grid|spatial_objects", true),
            (UnwrapSingleList(), "output|bgr_grid|spatial_objects|grouped", false),
            (UnwrapSingleList(), "input|bgr_grid|spatial_objects|grouped", true),
            (GetPosition(), "output|bgr_grid|spatial_objects|grouped|single_value", false),
            (GetPosition(), "input|bgr_grid|spatial_objects|grouped|single_value", true),
            (GetSize(), "input|bgr_grid|spatial_objects|grouped|single_value", true),
            (SeparateAxis(), "input|bgr_grid|spatial_objects|grouped|single_value|obj_size", true),
        ]
        solution = create_solution(task_info["train"], operations)
        @test test_solution(solution, task_info["test"])
    end

    @testset "ea786f4a" begin
        fname = "../data/training/ea786f4a.json"
        task_info = get_taskdef(fname)
        operations = [
            (BackgroundColor(), "input", true),
            (BackgroundColor(), "output", false),
            (SolidObjects(), "output|bgr_grid", false),
            (SolidObjects(), "input|bgr_grid", true),
            (UniteTouching(), "output|bgr_grid|spatial_objects", false),
            (UnwrapSingleList(), "output|bgr_grid|spatial_objects|united_touch", false),
            (VerticalSymmetry(), "output|bgr_grid|spatial_objects|united_touch|single_value", false),
            (HorisontalSymmetry(), "output|bgr_grid|spatial_objects|united_touch|single_value|vert_kernel", false),
            (UnwrapSingleList(), "input|bgr_grid|spatial_objects", true),
            (
                DotProductClass(),
                "output|bgr_grid|spatial_objects|united_touch|single_value|vert_kernel|horz_kernel",
                false,
            ),
        ]
        solution = create_solution(task_info["train"], operations)
        @test test_solution(solution, task_info["test"])
    end
end

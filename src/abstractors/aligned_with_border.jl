

struct AlignedWithBorder <: ComputeFunctionClass end
@memoize abs_keys(::AlignedWithBorder) = ["border_alignment"]
@memoize aux_keys(::AlignedWithBorder) = ["grid_size"]

check_task_value(::AlignedWithBorder, ::Object, data, aux_values) = true

to_abstract_value(p::Abstractor, ::AlignedWithBorder, source_value::Object, grid_size::Tuple{Int64,Int64}) =
    Dict(p.output_keys[1] => (source_value.position[1] == 1,
        source_value.position[2] == 1,
        source_value.position[1] + size(source_value.shape)[1] - 1 == grid_size[1],
        source_value.position[2] + size(source_value.shape)[2] - 1 == grid_size[2],))

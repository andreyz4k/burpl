

struct AlignedWithBorder <: ComputeFunctionClass end
@memoize abs_keys(cls::AlignedWithBorder) = ["border_alignment"]
@memoize aux_keys(cls::AlignedWithBorder) = ["grid_size"]

check_task_value(cls::AlignedWithBorder, value::Object, data, aux_values) = true

to_abstract_value(p::Abstractor, cls::AlignedWithBorder, source_value::Object, aux_values) =
    Dict(p.output_keys[1] => (source_value.position[1] == 1,
        source_value.position[2] == 1,
        source_value.position[1] + size(source_value.shape)[1] - 1 == aux_values[1][1],
        source_value.position[2] + size(source_value.shape)[2] - 1 == aux_values[1][2],))

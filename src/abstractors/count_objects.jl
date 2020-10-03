

struct CountObjects <: AbstractorClass end

CountObjects(key, to_abs) = Abstractor(CountObjects(), key, to_abs)
@memoize priority(::CountObjects) = 30
@memoize abs_keys(::CountObjects) = ["counted", "length"]

check_task_value(::CountObjects, value::AbstractVector, data, aux_values) = true

to_abstract_value(p::Abstractor, ::CountObjects, source_value::AbstractVector) =
    Dict(
        p.output_keys[1] => source_value,
        p.output_keys[2] => length(source_value)
    )

from_abstract_value(p::Abstractor, ::CountObjects, source_values) =
    Dict(p.output_keys[1] => source_values[1][1:min(source_values[2], length(source_values[1]))])

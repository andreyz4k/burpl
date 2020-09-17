
struct SortArray <: AbstractorClass end

SortArray(key, to_abs) = Abstractor(SortArray(), key, to_abs)
@memoize abs_keys(p::SortArray) = ["sorted"]

init_create_check_data(cls::SortArray, key, solution) = Dict("effective" => false)

function check_task_value(cls::SortArray, value::AbstractVector{T}, data, aux_values) where {T}
    if !hasmethod(isless, Tuple{T,T})
        return false
    end

    if sort(value) != value
        data["effective"] = true
    end
    return true
end

create_abstractors(cls::SortArray, data, key) =
    data["effective"] ? invoke(create_abstractors, Tuple{AbstractorClass,Any,Any}, cls, data, key) : []

to_abstract_value(p::Abstractor, cls::SortArray, source_value, aux_values) =
    Dict(p.output_keys[1] => sort(source_value))

from_abstract_value(p::Abstractor, cls::SortArray, source_values) =
    Dict(p.output_keys[1] => source_values[1])

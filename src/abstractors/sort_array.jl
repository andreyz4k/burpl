
struct SortArray <: AbstractorClass end

SortArray(key, to_abs) = Abstractor(SortArray(), key, to_abs)
abs_keys(::SortArray) = ["sorted"]

init_create_check_data(::SortArray, key, solution) = Dict("effective" => false)

function check_task_value(::SortArray, value::AbstractVector{T}, data, aux_values) where {T}
    if !hasmethod(isless, Tuple{T,T})
        return false
    end

    if sort(value) != value
        data["effective"] = true
    end
    return true
end

to_abstract_value(p::Abstractor, ::SortArray, source_value) =
    Dict(p.output_keys[1] => sort(source_value))

from_abstract_value(p::Abstractor, ::SortArray, source_value) =
    Dict(p.output_keys[1] => source_value)

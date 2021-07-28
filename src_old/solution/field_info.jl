
struct FieldInfo
    type::Type
    derived_from::String
    precursor_types::Vector{Type}
    previous_fields::Set{String}
    FieldInfo(type::Type, derived_from::String, precursor_types, previous_fields) =
        new(type, derived_from, precursor_types, Set(previous_fields))
end

Base.show(io::IO, f::FieldInfo) =
    print(io, "FieldInfo(", f.type, ", \"", f.derived_from, "\", ", f.precursor_types, ", ", f.previous_fields, ")")

using ..PatternMatching: Matcher, unwrap_matcher

_get_type(::T) where {T} = T
_get_type(val::Matcher) = _get_type(unwrap_matcher(val)[1])
function _get_type(val::Dict)
    key, value = first(val)
    Dict{_get_type(key),_get_type(value)}
end
_get_type(val::Vector) = Vector{_get_type(val[1])}

function FieldInfo(value, derived_from, precursor_types, previous_fields)
    type = _get_type(value)
    return FieldInfo(type, derived_from, unique([precursor_types..., type]), union(previous_fields...))
end

_is_valid_value(val) = true
_is_valid_value(val::Union{Array,Dict}) = !isempty(val)

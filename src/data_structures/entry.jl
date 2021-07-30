

struct Entry
    type::Type
    values::Vector
end

_get_type(::T) where T = T

Entry(values) = Entry(_get_type(values[1]), values)

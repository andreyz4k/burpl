

struct Entry
    type::Type
    values::Vector
end
Base.show(io::IO, entry::Entry) = print(io, "Entry(", entry.type, ", ", entry.values, ")")

_get_type(::T) where T = T

Entry(values) = Entry(_get_type(values[1]), values)

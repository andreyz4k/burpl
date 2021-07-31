

struct Entry
    type::Type
    values::Vector
end
Base.show(io::IO, entry::Entry) = print(io, "Entry(", entry.type, ", ", entry.values, ")")

_get_type(::T) where T = T

Entry(values) = Entry(_get_type(values[1]), values)

Base.:(==)(e1::Entry, e2::Entry) = e1.type == e2.type && e1.values == e2.values
Base.hash(e::Entry, h::UInt64) = hash(e.type, h) + hash(e.values, h)

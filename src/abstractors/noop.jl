

struct Noop <: AbstractorClass end

to_abstract_value(p::Abstractor, ::Noop, source_value, aux_values...) = Dict()
from_abstract_value(p::Abstractor, ::Noop, source_values) = Dict()

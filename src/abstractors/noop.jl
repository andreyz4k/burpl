

struct Noop <: AbstractorClass end

to_abstract_value(p::Abstractor, cls::Noop, source_value, aux_values) = Dict()
from_abstract_value(p::Abstractor, cls::Noop, source_values) = Dict()

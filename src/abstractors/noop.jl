

struct Noop <: AbstractorClass end

to_abstract_value(p::Abstractor{Noop}, source_value...) = Dict()
from_abstract_value(p::Abstractor{Noop}, source_values...) = Dict()

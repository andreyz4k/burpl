
struct IgnoreBackground <: AbstractorClass end

IgnoreBackground(key, to_abs) = Abstractor(IgnoreBackground(), key, to_abs)
@memoize aux_keys(p::IgnoreBackground) = ["background"]
@memoize priority(p::IgnoreBackground) = 3

function create(cls::IgnoreBackground, solution, key)::Array{Tuple{Float64,NamedTuple{(:to_abstract, :from_abstract),Tuple{Abstractor,Abstractor}}},1}
    if startswith(key, "projected|") || (!in(key, solution.unused_fields) && !in(key, solution.unfilled_fields))
        return []
    end
    invoke(create, Tuple{AbstractorClass,Any,Any}, cls, solution, key)
end

import ..ObjectPrior:Object,get_color

check_task_value(cls::IgnoreBackground, value, data, aux_values) = false
check_task_value(cls::IgnoreBackground, value::Array{Object,1}, data, aux_values) =
    all(get_color(obj) == aux_values[1] for obj in value)

# function get_aux_values_for_task(cls::IgnoreBackground, task_data, key, solution)
#     bgr_key = get_aux_keys_for_key(cls, key)[1]
#     if haskey(task_data, bgr_key) && !in(bgr_key, solution.unfilled_fields)
#         return [task_data[bgr_key]]
#     else
#         return [0]
#     end
# end

to_abstract_value(p::Abstractor, cls::IgnoreBackground, source_value, aux_values) = Dict()
from_abstract_value(p::Abstractor, cls::IgnoreBackground, source_values) = Dict()

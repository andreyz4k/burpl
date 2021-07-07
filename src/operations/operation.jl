export Operations
module Operations

export Operation
export Project

abstract type OperationClass end
abstract type Operation end

get_sorting_keys(operation::Operation) = operation.output_keys
needed_input_keys(operation::Operation) = operation.input_keys

using ..PatternMatching: update_value, apply_func
using ..Taskdata: TaskData, num_examples

include("set_const.jl")
include("copy_param.jl")
include("map_values.jl")
include("inc_param.jl")
include("inc_by_param.jl")
include("dec_by_param.jl")
include("mult_param.jl")
include("mult_by_param.jl")
include("wrap_matcher.jl")
include("project.jl")

end

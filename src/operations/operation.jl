export Operations
module Operations

export Operation
export Project

abstract type OperationClass end
abstract type Operation end

get_sorting_keys(operation::Operation) = operation.output_keys
needed_input_keys(operation::Operation) = operation.input_keys

include("project.jl")
include("abstractors.jl")

end

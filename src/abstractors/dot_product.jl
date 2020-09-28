

abstract type DotProductClass <: OperationClass end

@memoize abstractor_classes(cls::DotProductClass) = []

struct DotProduct <: Operation
    abstractors::Array{Abstractor}
    input_keys::Array{String}
    output_keys::Array{String}
end


function (p::DotProduct)(task_data)
    inner_keys = []
    for abstractor in p.abstractors[1:end - 1]
        task_data = abstractor(task_data)
        append!(inner_keys, abstractor.output_keys)
    end
    task_data = p.abstractors[end](task_data)
    for key in inner_keys
        delete!(task_data, key)
    end
    task_data
end

using ..Solutions:Solution

function create(cls::DotProductClass, solution, key)::Array{Tuple{Float64,NamedTuple{(:to_abstract, :from_abstract),Tuple{DotProduct,DotProduct}}},1}
    abstractor_paths = Array{Abstractor}[]
    for abs_class in abstractor_classes(cls)
        available_abstractors = create(abs_class, solution, key)
        Solution(solution)
    end

end

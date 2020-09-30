
function _unroll_results(matches)
    if isempty(matches)
        return [[]]
    end
    out = []
    for value in unpack_value(matches[1])
        for tail in _unroll_results(view(matches, 2:length(matches)))
            push!(out, vcat([value], tail))
        end
    end
    out
end

using ..Abstractors:CountObjects

function find_const_array(taskdata::Vector{Dict{String,Any}}, _, key::String)
    result = []
    for task_data in taskdata
        if !isa(task_data[key], AbstractVector)
            return []
        end

        if length(task_data[key]) > length(result)
            append!(result, view(task_data[key], length(result) + 1:length(task_data[key])))
        end
        for (i, task_value) in enumerate(task_data[key])
            res = compare_values(result[i], task_value)
            if isnothing(res)
                return []
            end
            result[i] = res
        end
    end
    counter = CountObjects(key, false)
    return [(SetConst(counter.input_keys[1], array_value), counter) for array_value in _unroll_results(result)]
end

using ..Solutions:Solution

function find_matched_const_array(key, solution::Solution)
    new_solutions = []
    transformers = find_const_array(solution.taskdata, union(solution.unfilled_fields, solution.transformed_fields), key)
    for transformer_pair in transformers
        new_solution = Solution(solution, transformer_pair[2],
                                CountObjects(key, true))
        new_solution = Solution(new_solution, transformer_pair[1],
                                added_complexity=transformer_pair[1].complexity)
        push!(new_solutions, new_solution)
    end
    return new_solutions
end

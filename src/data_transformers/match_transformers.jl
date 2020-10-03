
function get_match_transformers(taskdata::Array{Dict{String,Any}}, invalid_sources, key)
    result = []
    find_matches_funcs = [
        find_const,
        find_dependent_key,
        find_proportionate_key,
        find_shifted_key,
        find_proportionate_by_key,
        find_shifted_by_key
    ]
    for func in find_matches_funcs
        if length(result) == 1
            break
        end
        append!(result, func(taskdata, invalid_sources, key))
    end
    return result

end

using ..Solutions:Solution

function find_matched_fields(key, solution::Solution, get_transformers_func)
    new_solutions = []
    transformers = get_transformers_func(solution.taskdata, union(solution.unfilled_fields, solution.transformed_fields), key)
    for transformer in transformers
        if transformer.generability > 5
            continue
        end
        new_solution = Solution(solution, transformer,
                                added_complexity=transformer.complexity)
        push!(new_solutions, new_solution)
    end
    return new_solutions
end

function exact_match_fields(solution::Solution)
    for key in solution.unfilled_fields
        new_solutions = find_matched_fields(key, solution, get_match_transformers)
        if !isempty(new_solutions)
            return reduce(
                vcat,
                (exact_match_fields(new_solution) for new_solution in new_solutions),
                init=[]
            )
        end
    end
    return [solution]
end


function match_fields(solution::Solution)
    out = []
    for new_solution in exact_match_fields(solution)
        # println(new_solution.unfilled_fields)
        # println(new_solution)
        mapped_solutions = Set([new_solution])
        for key in new_solution.unfilled_fields
            next_solutions = union((find_matched_fields(key, cur_solution, find_mapped_key)
                                   for cur_solution in mapped_solutions)...)
            union!(mapped_solutions, next_solutions)
            # println(length(mapped_solutions))
        end
        append!(out, mapped_solutions)
    end
    return out
end

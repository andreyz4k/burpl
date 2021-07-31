
module Solve


using ..DataStructures: SolutionFinder
using DataStructures
using Base.Iterators: flatten
using ..Abstractors: get_valid_abstractors_for_type, get_abstractor_priority, try_apply_abstractor
using ..PatternMatching: match_field
using IterTools: imap

function init_solve_loop(finder::SolutionFinder)
    queue = PriorityQueue()
    for key in flatten([keys(finder.root_branch.known_fields), keys(finder.root_branch.unknown_fields)])
        enqueue_key!(queue, finder.root_branch, key)
    end
    queue
end

function enqueue_key!(queue, branch, key)
    entry = branch[key]
    for abstractor in get_valid_abstractors_for_type(entry.type)
        queue[(branch, key, abstractor)] = get_abstractor_priority(abstractor, entry)
    end
end

function run_solve_loop(queue, target_keys)
    flatten(imap(1:1000) do iteration_number
        if isempty(queue)
            return []
        end
        (branch, key, abstractor) = dequeue!(queue)
        loop_iteration(queue, branch, key, abstractor, target_keys)
    end)
end

function loop_iteration(queue, branch, key, abstractor, target_keys)
    new_keys = try_apply_abstractor(branch, key, abstractor)
    if isnothing(new_keys)
        return
    end
    flatten(imap(new_keys) do k
        new_branches = match_field(branch, k)
        skipmissing(imap(new_branches) do new_branch
            if all(haskey(new_branch.known_fields, target_key) for target_key in target_keys)
                return extract_solution(new_branch, target_keys)
            end
            enqueue_key!(queue, new_branch, k)
            return missing
        end)
    end)
end

function solve(finder)
    target_keys = collect(keys(finder.root_branch.unknown_fields))
    queue = init_solve_loop(finder)
    run_solve_loop(queue, target_keys)
end

include("extract_solution.jl")

end

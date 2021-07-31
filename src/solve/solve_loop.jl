
module Solve


using ..DataStructures: SolutionFinder
using DataStructures
using Base.Iterators: flatten
using ..Abstractors: get_valid_abstractors_for_type, get_abstractor_priority, try_apply_abstractor
using ..PatternMatching: match_field

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

function run_solve_loop(queue)
    while !isempty(queue)
        (branch, key, abstractor) = dequeue!(queue)
        loop_iteration(queue, branch, key, abstractor)
    end
end

function loop_iteration(queue, branch, key, abstractor)
    new_keys = try_apply_abstractor(branch, key, abstractor)
    if isnothing(new_keys)
        return
    end
    for k in new_keys
        new_branches = match_field(branch, k)
        for new_branch in new_branches
            enqueue_key!(queue, new_branch, k)
        end
    end
    @info(branch)
end

function solve(finder)
    queue = init_solve_loop(finder)
    run_solve_loop(queue)
end

end

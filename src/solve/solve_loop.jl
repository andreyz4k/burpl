
module Solve


using ..DataStructures: SolutionFinder
using DataStructures
using Base.Iterators: flatten
using ..Abstractors: get_valid_abstractors_for_type, get_abstractor_priority, try_apply_abstractor

function init_solve_loop(finder::SolutionFinder)
    queue = PriorityQueue()
    for (key, entry) in flatten([finder.root_branch.known_fields, finder.root_branch.unknown_fields])
        for abstractor in get_valid_abstractors_for_type(entry.type)
            queue[(finder.root_branch, key, abstractor)] = get_abstractor_priority(abstractor, entry)
        end
    end
    queue
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
end

function solve(finder)
    queue = init_solve_loop(finder)
    run_solve_loop(queue)
end

end

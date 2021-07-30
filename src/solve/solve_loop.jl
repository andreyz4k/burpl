
module Solve


using ..DataStructures: SolutionFinder
using DataStructures

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

end

function solve(finder)
    queue = init_solve_loop(finder)
    run_solve_loop(queue)
end

end

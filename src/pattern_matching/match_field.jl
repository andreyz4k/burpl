using IterTools: imap
using Base.Iterators: flatten

using ..DataStructures: SolutionBranch

function match_field(branch, key)
    if haskey(branch.known_fields, key)
        matchers = [find_exact_match]
    else
        matchers = [find_const, find_exact_match]
    end
    operations = flatten(imap(matchers) do matcher
        matcher(branch, key)
    end)
    new_branches = []
    for operation in operations
        outputs = operation(branch)
        updated_keys = [k for (k, val) in outputs if branch[k] != val]
        if !isempty(updated_keys)
            @warn("move to new branch")
            new_branch = SolutionBranch(
                Dict(),
                Dict(),
                copy(branch.fill_percentages),
                [],
                branch,
                [],
                deepcopy(branch.either_groups),
            )
            affected_either_groups = filter(gr -> any(in(k, gr) for k in updated_keys), branch.either_groups)

        else
            push!(branch.operations, operation)
            mark_filled_field(branch, key)
            return [branch]
        end
    end
    return [branch]
end

using IterTools: imap
using Base.Iterators: flatten

function match_field(branch, key)
    if haskey(branch.known_fields, key)
        matchers = [find_exact_match]
    else
        matchers = [find_const, find_exact_match]
    end
    operations = flatten(imap(matchers) do matcher
        matcher(branch, key)
    end)
    for operation in operations
        outputs = operation(branch)
        if any(branch[k] != val for (k, val) in outputs)
            @warn("move to new branch")
        else
            push!(branch.operations, operation)
        end
        mark_filled_field(branch, key)
        return [branch]
    end
    return [branch]
end

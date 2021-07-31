using IterTools: imap
using Base.Iterators: flatten

function match_field(branch, key)
    if haskey(branch.known_fields, key)
        matchers = []
    else
        matchers = [find_const]
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
    end
    return operations
end

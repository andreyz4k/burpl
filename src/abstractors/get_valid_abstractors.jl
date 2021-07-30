
abstracts_types(::Any) = []

using InteractiveUtils: subtypes
all_subtypes(cls) = reduce(vcat, ((isabstracttype(c) ? all_subtypes(c) : [c]) for c in subtypes(cls)), init = [])
abstractor_map = Dict()
for cls in all_subtypes(Abstractor)
    for t in abstracts_types(cls)
        if !haskey(abstractor_map, t)
            abstractor_map[t] = [cls]
        else
            push!(abstractor_map[t], cls)
        end
    end
end

function get_valid_abstractors_for_type(type)
    result = []
    for (t, abstractors) in abstractor_map
        if type <: t
            append!(result, abstractors)
        end
    end
    return result
end

function get_abstractor_priority(abstractor, entry)
    return 1
end

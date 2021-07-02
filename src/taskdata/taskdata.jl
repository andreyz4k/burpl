export Taskdata
module Taskdata

struct TaskData <: AbstractDict{String,Any}
    persistent_data::Dict{String,Vector}
    updated_values::Dict{String,Vector}
    keys_to_delete::Set{String}
end

Base.show(io::IO, t::TaskData) =
    print(io, "TaskData(", t.persistent_data, ", ", t.updated_values, ", ", t.keys_to_delete, ")")

Base.copy(t::TaskData) = TaskData(t.persistent_data, copy(t.updated_values), copy(t.keys_to_delete))

function persist_data(taskdata::TaskData)
    persistent_data = copy(taskdata.persistent_data)
    for key in taskdata.keys_to_delete
        delete!(persistent_data, key)
    end
    merge!(persistent_data, filter(kv -> !in(kv[1], taskdata.keys_to_delete), taskdata.updated_values))
    TaskData(persistent_data, Dict{String,Any}(), Set{String}())
end

function Base.setindex!(t::TaskData, v, k)
    if in(k, t.keys_to_delete)
        delete!(t.keys_to_delete, k)
    end
    t.updated_values[k] = v
end

function Base.length(t::TaskData)
    length(t.persistent_data) + length(t.updated_values) + length(t.keys_to_delete)
end

function Base.haskey(t::TaskData, key)
    if key in t.keys_to_delete
        return false
    end
    return haskey(t.updated_values, key) || haskey(t.persistent_data, key)
end

function Base.get(t::TaskData, key, default)
    if !haskey(t, key)
        return default
    end
    if haskey(t.updated_values, key)
        return get(t.updated_values, key, default)
    end
    return get(t.persistent_data, key, default)
end

function Base.iterate(t::TaskData)
    return iterate(t, (1, nothing))
end

function Base.iterate(t::TaskData, state::Tuple{Int,Any})
    branch, internal_state = state
    if branch == 1
        if isnothing(internal_state)
            next = iterate(t.updated_values)
        else
            next = iterate(t.updated_values, internal_state)
        end
        if isnothing(next)
            return iterate(t, (2, nothing))
        end
        if in(next[1][1], t.keys_to_delete)
            return iterate(t, (1, next[2]))
        end
        return next[1], (1, next[2])
    else
        if isnothing(internal_state)
            next = iterate(t.persistent_data)
        else
            next = iterate(t.persistent_data, internal_state)
        end
        if isnothing(next)
            return nothing
        end
        if in(next[1][1], t.keys_to_delete) || haskey(t.updated_values, next[1][1])
            return iterate(t, (2, next[2]))
        end
        return next[1], (2, next[2])
    end
end

Base.merge(t::TaskData, others::AbstractDict...) = TaskData(
    t.persistent_data,
    merge(t.updated_values, others...),
    setdiff(t.keys_to_delete, [keys(o) for o in others]...),
)

Base.filter(f::Function, t::TaskData) = TaskData(
    t.persistent_data,
    filter(f, t.updated_values),
    union(t.keys_to_delete, keys(filter(!f, t.persistent_data))),
)

function Base.delete!(t::TaskData, key)
    push!(t.keys_to_delete, key)
end

function updated_keys(t::TaskData)
    return filter(k -> !in(k, t.keys_to_delete), keys(t.updated_values))
end

end

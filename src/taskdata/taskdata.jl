export Taskdata
module Taskdata

struct TaskData <: AbstractDict{String,Any}
    persistent_data::Dict{String,Any}
    updated_values::Dict{String,Any}
    keys_to_delete::Set{String}
    complexity_scores::Dict{String,Float64}
    value_hashes::Dict{String,UInt64}
end

Base.show(io::IO, t::TaskData) =
    print(io, "TaskData(", t.persistent_data, ", ", t.updated_values, ", ", t.keys_to_delete, ")")

Base.copy(t::TaskData) = TaskData(
    t.persistent_data,
    copy(t.updated_values),
    copy(t.keys_to_delete),
    copy(t.complexity_scores),
    copy(t.value_hashes),
)

using ..Complexity: get_complexity

function persist_data(taskdata::TaskData)
    persistent_data = copy(taskdata.persistent_data)
    complexity_scores = copy(taskdata.complexity_scores)
    value_hashes = copy(taskdata.value_hashes)
    for key in taskdata.keys_to_delete
        delete!(persistent_data, key)
        delete!(complexity_scores, key)
        delete!(value_hashes, key)
    end
    for (key, value) in taskdata.updated_values
        if !in(key, taskdata.keys_to_delete)
            persistent_data[key] = value
            complexity_scores[key] = get_complexity(value)
            value_hashes[key] = hash(value)
        end
    end
    TaskData(persistent_data, Dict{String,Any}(), Set{String}(), complexity_scores, value_hashes)
end

function get_value_complexity(taskdata::TaskData, key)::Float64
    if haskey(taskdata.updated_values, key) || !haskey(taskdata.complexity_scores, key)
        return get_complexity(taskdata[key])
    end
    return taskdata.complexity_scores[key]
end

function get_value_hash(taskdata::TaskData, key)::Float64
    if haskey(taskdata.updated_values, key) || !haskey(taskdata.value_hashes, key)
        return hash(taskdata[key])
    end
    return taskdata.value_hashes[key]
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
    t.complexity_scores,
    t.value_hashes,
)

Base.filter(f::Function, t::TaskData) = TaskData(
    t.persistent_data,
    filter(f, t.updated_values),
    union(t.keys_to_delete, keys(filter(!f, t.persistent_data))),
    t.complexity_scores,
    t.value_hashes,
)

function Base.delete!(t::TaskData, key)
    push!(t.keys_to_delete, key)
end

function updated_keys(t::TaskData)
    return filter(k -> !in(k, t.keys_to_delete), keys(t.updated_values))
end

function updated_keys(taskdata::Vector{TaskData})
    union((updated_keys(task) for task in taskdata)...)
end

Base.keys(t::TaskData) = filter(k -> !in(k, t.keys_to_delete), union(keys(t.updated_values), keys(t.persistent_data)))

end

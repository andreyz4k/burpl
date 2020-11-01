
using ..PatternMatching:Matcher

struct WrapMatcher <: Operation
    operations
    input_keys
    output_keys
    aux_keys 
end

Base.show(io::IO, wr::WrapMatcher) = print(io, "WrapMatcher(", wr.operations[1], ", ", filter(k -> !in(k, wr.operations[1].input_keys), wr.input_keys), ")")

Base.:(==)(a::WrapMatcher, b::WrapMatcher) = a.operations == b.operations

_check_matcher(::Any) = false
_check_matcher(::Matcher) = true
_check_matcher(value::AbstractDict) = any(_check_matcher(v) for v in values(value))
_check_matcher(value::AbstractVector) = any(_check_matcher(v) for v in value)

_filter_unmatched_keys(keys, taskdata) =
    filter(key -> any(_check_matcher(task[key]) for task in taskdata), keys)

function wrap_operation(taskdata, operation)
    unmatched_keys = _filter_unmatched_keys(operation.output_keys, taskdata)
    if isempty(unmatched_keys)
        return taskdata, operation
    end
    for key in unmatched_keys, task in taskdata
        if !haskey(task, key * "|unfilled")
            task[key * "|unfilled"] = task[key]
        end
        delete!(task, key)
    end
    return taskdata, WrapMatcher(
        [operation, (CopyParam(k, k * "|unfilled") for k in unmatched_keys)...], 
        vcat(operation.input_keys, [k * "|unfilled" for k in unmatched_keys]), 
        operation.output_keys, 
        operation.aux_keys
    )
end

get_unfilled_inputs(operation, taskdata) = operation.input_keys

get_unfilled_inputs(operation::WrapMatcher, taskdata) =
    _filter_unmatched_keys(operation.input_keys, taskdata)

function (wrapper::WrapMatcher)(observed_data)
    filled = false
    processed_data = observed_data
    for op in wrapper.operations
        if all(haskey(processed_data, k) && !_check_matcher(processed_data[k]) for k in op.input_keys)
            processed_data = op(processed_data)
        end
    end
    if isnothing(processed_data)
        processed_data = observed_data
        for op in wrapper.operations
            if all(!_check_matcher(processed_data[k]) for k in op.input_keys)
                processed_data = op(processed_data)
            end
        end
    end
    if any(_check_matcher(processed_data[k]) for k in wrapper.output_keys)
        return observed_data
    end
    return processed_data
end


using ..Complexity: get_complexity

struct MapValues <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    match_pairs::Dict
    complexity::Float64
    function MapValues(key, inp_key, match_pairs)
        complexity = get_complexity(match_pairs)
        new([inp_key], [key], match_pairs, get_complexity(match_pairs))
    end
end

Base.show(io::IO, op::MapValues) =
    print(io, "MapValues(\"", op.output_keys[1], "\", \"", op.input_keys[1], "\", ", op.match_pairs, ")")

Base.:(==)(a::MapValues, b::MapValues) =
    a.output_keys == b.output_keys && a.input_keys == b.input_keys && a.match_pairs == b.match_pairs
Base.hash(op::MapValues, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h) + hash(op.match_pairs, h)

function (op::MapValues)(taskdata::TaskData)
    output_value = [
        isa(input_value, Dict) ? Dict(key => op.match_pairs[value] for (key, value) in input_value) :
        op.match_pairs[input_value] for input_value in taskdata[op.input_keys[1]]
    ]
    update_value(taskdata, op.output_keys[1], output_value)
end

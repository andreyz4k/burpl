using ..PatternMatching:Matcher

struct MultParam <: Operation
    input_keys::Array{String}
    output_keys::Array{String}
    factor::Int64
    complexity::Float64
    MultParam(key, inp_key, factor) = new([inp_key], [key, key * "|mult_factor"], factor, 1)
end

Base.show(io::IO, op::MultParam) = print(io, "MultParam(", op.output_keys[1], ", ", op.input_keys[1], ", ", op.factor, ")")

Base.:(==)(a::MultParam, b::MultParam) = a.output_keys == b.output_keys && a.input_keys == b.input_keys && a.factor == b.factor
Base.hash(op::MultParam, h::UInt64) = hash(op.output_keys, h) + hash(op.input_keys, h) + hash(op.factor, h)

function (op::MultParam)(task_data)
    output_value = mult_value(task_data[op.input_keys[1]], op.factor)
    data = update_value(task_data, op.output_keys[1], output_value)
    update_value(data, op.output_keys[2], op.factor)
end

_init_factors(::Any...) = [-9, -8, -7, -6, -5, -4, -3, -2, -1, 2, 3, 4, 5, 6, 7, 8, 9]

_factor_filter(factor, input_value, output_value, _) = !isnothing(common_value(apply_func(input_value, (x, y) -> x .* y, factor), output_value))

find_proportionate_key(taskdata::Vector{Dict{String,Any}}, field_info, invalid_sources::AbstractSet{String}, key::String) =
    find_matching_for_key(taskdata, field_info, invalid_sources, key, _init_factors, _factor_filter, MultParam, (_, _) -> true)

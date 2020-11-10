

struct ArrayPrefix{T} <: Matcher{T}
    value
    ArrayPrefix(val::Vector{S}) where S = new{Vector{S}}(val)
    ArrayPrefix(val::Vector{<:Matcher{S}}) where S = new{Vector{S}}(val)
end

Base.:(==)(a::ArrayPrefix, b::ArrayPrefix) = a.value == b.value
Base.hash(p::ArrayPrefix, h::UInt64) = hash(p.value, h)
Base.show(io::IO, p::ArrayPrefix{T}) where {T} = print(io, "ArrayPrefix{", T, "}(", p.value, ")")


match(::Any, ::ArrayPrefix) = nothing

function match(val1::T, val2::ArrayPrefix{T}) where T <: AbstractVector
    if length(val1) >= length(val2.value) && !isnothing(common_value(val1[1:length(val2.value)], val2.value))
        return val1
    end
    return nothing
end

function match(val1::ArrayPrefix{T}, val2::ArrayPrefix{T}) where T <: AbstractVector
    if all(v1 == v2 for (v1, v2) in zip(val1.value, val2.value))
        if length(val1.value) >= length(val2.value)
            return val1
        else
            return val2
        end
    end
    return nothing
end

match(val1::Either, val2::ArrayPrefix) =
    invoke(match, Tuple{Any,Either}, val2, val1)

match(::Matcher, ::ArrayPrefix) = nothing

unpack_value(p::ArrayPrefix) = unpack_value(p.value)

unwrap_matcher(p::ArrayPrefix) = [p.value]

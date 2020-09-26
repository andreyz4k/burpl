import Base.Iterators: drop, take
import Base: iterate, eltype, length, size, peek
import Base: tail
import Base: IteratorSize, IteratorEltype
import Base: SizeUnknown, IsInfinite, HasLength, HasShape
import Base: HasEltype, EltypeUnknown

import Base: OneTo

struct Padded_it{I}
    it::I
    default
end
IteratorSize(::Type{Padded_it{I}}) where I = IteratorSize(I)
IteratorEltype(::Type{Padded_it{I}}) where I = IteratorEltype(I)
eltype(::Type{Padded_it{I}}) where I = eltype(I)
length(i::Padded_it) = length(i.it)
size(i::Padded_it,dim...) = size(i.it, dim...)
axes(i::Padded_it,dim...) = axes(i.it, dim...)
function iterate(it::Padded_it, state...)
    isnothing(state) && return nothing
    ~isempty(state) && isnothing(last(state)) && return nothing
    return iterate(it.it, state...)
end

struct Zip_longest{IS <: Tuple}
    is::IS
end
IteratorSize(::Type{Zip_longest{IS}}) where {IS <: Tuple} = Base.Iterators._zip_iterator_size(IS)
IteratorEltype(::Type{Zip_longest{IS}}) where {IS <: Tuple} = Base.Iterators._zip_iterator_eltype(IS)
eltype(::Type{Zip_longest{IS}}) where {IS <: Tuple} = Base.Iterators._zip_eltype(IS)
length(it::Zip_longest) = maximum(length.(it.is))
size(it::Zip_longest) = mapreduce(size, _zip_longest_promote_shape, it.is)
axes(it::Zip_longest) = mapreduce(axes, _zip_longest_promote_shape, it.is)
function iterate(it::Zip_longest, state...)
    cur = iterate.(it.is, state...)
    if all(isnothing.(cur))
        return nothing
    end
    outval = Vector{Any}(nothing, length(cur))
    outstate = Vector{Any}(nothing, length(cur))
    for (i, c) in enumerate(cur)
        if isnothing(c)
            outval[i] = it.is[i].default
            outstate[i] = nothing
            continue
        end
        outval[i] = c[1]
        outstate[i] = c[2]
    end
    return (Tuple(outval), Tuple(outstate))
end


_zip_longest_promote_shape((a,)::Tuple{OneTo}, (b,)::Tuple{OneTo}) = (union(a, b),)
_zip_longest_promote_shape((m,)::Tuple{Integer},(n,)::Tuple{Integer}) = (max(m, n),)
_zip_longest_promote_shape(a, b) = promote_shape(a, b)

"""
`zip_longest(iters...; default=nothing)`
For one or more iterable objects, return an iterable of tuples, where the `i`th tuple
contains the `i`th component of each input iterable if it is not finished, and `default`
otherwise. `default` can be a scalar, or a tuple with one default per iterable.
"""
function zip_longest(its...;default=nothing)
    return Zip_longest(Tuple(Padded_it.(its, default)))
end

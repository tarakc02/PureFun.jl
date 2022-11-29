abstract type PFSet{T} <: AbstractSet{T} end

Base.eltype(::Type{<:PFSet{T}}) where T = T
Base.union(s::PFSet, iter) = reduce(push, iter, init = s)
Base.union(s::PFSet, sets...) = reduce(union, sets, init=s)

function Base.intersect(s::PFSet, iter)
    out = empty(s)
    for i in iter
        if i ∈ s out = push(out, i) end
    end
    return out
end
Base.intersect(s::PFSet, sets...) = reduce(sets, intersect, init=s)

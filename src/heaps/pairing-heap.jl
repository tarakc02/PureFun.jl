module Pairing

using ...PureFun
using ...PureFun.Lists.Linked

struct Empty{T} <: PureFun.PFHeap{T} end

struct NonEmpty{T, H} <: PureFun.PFHeap{T} where {H <: Linked.List{PureFun.PFHeap{T}}}
    x::T
    hs::H
end

Heap{T} = Union{Empty{T}, NonEmpty{T}} where {T}

Heap{T}() where T = Empty{T}()

Base.isempty(::Empty) = true
Base.isempty(::NonEmpty) = false

const leq = PureFun.leq
elem(h) = h.x
heaps(h) = h.hs
#PureFun.find_min(h::NonEmpty) = elem(h)
Base.minimum(h::NonEmpty) = elem(h)

Base.length(h::Empty) = 0
Base.length(h::NonEmpty{ T, Linked.Empty{ NonEmpty{T} } }) where T = 1
Base.length(h::NonEmpty) = 1 + sum(length(h0) for h0 in heaps(h))

Base.merge(h::Heap, ::Empty) = h
Base.merge(::Empty, h::NonEmpty) = h
function Base.merge(h1::NonEmpty, h2::NonEmpty)
    x,y = elem(h1), elem(h2)
    hs1, hs2 = heaps(h1), heaps(h2)
    leq(x, y) ? NonEmpty(x, cons(h2, hs1)) : NonEmpty(y, cons(h1, hs2))
end

PureFun.insert(h::Heap{T}, x::T) where T = merge(NonEmpty(x, Linked.List{NonEmpty{T}}()), h)

merge_pairs(::Linked.Empty{T}) where T = Heap{T}()
function merge_pairs(l)
    isempty(tail(l)) && return head(l)
    hs = l
    merged = Heap{eltype(l)}()
    while !isempty(hs)
        isempty(tail(hs)) && return merge(head(hs), merged)
        h1, h2, hs = head(hs), head(tail(hs)), tail(tail(hs))
        merged = merge(merge(h1, h2), merged)
    end
    return merged
end

PureFun.delete_min(h::NonEmpty) = merge_pairs(heaps(h))
PureFun.tail(h::Heap) = delete_min(h)

Heap(iter::Heap) = iter
Heap(iter) = reduce(insert, iter, init = Heap{eltype(iter)}())

end

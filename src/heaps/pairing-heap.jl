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
PureFun.find_min(h::NonEmpty) = elem(h)
Base.first(h::Heap) = find_min(h)

Base.merge(h::Heap, ::Heap) = h
function Base.merge(h1::NonEmpty, h2::NonEmpty)
    x,y = elem(h1), elem(h2)
    hs1, hs2 = heaps(h1), heaps(h2)
    leq(x, y) ? NonEmpty(x, cons(h2, hs1)) : NonEmpty(y, cons(h1, hs2))
end

PureFun.insert(h::Heap{T}, x::T) where T = merge(NonEmpty(x, Linked.List{Heap{T}}()), h)

merge_pairs(::Linked.Empty{T}) where T = Heap{T}()
function merge_pairs(l)
    isempty(tail(l)) && return first(l)
    h1, h2, hs = first(l), first(tail(l)), tail(tail(l))
    merge(
      merge(h1, h2),
      merge_pairs(hs)
     )
end

PureFun.delete_min(h::NonEmpty) = merge_pairs(heaps(h))
PureFun.tail(h::Heap) = delete_min(h)

Heap(iter::Heap) = iter
Heap(iter) = reduce(insert, iter, init = Heap{eltype(iter)}())

end

module Pairing

using ..PureFun
using ..PureFun.Linked

leq(o, x, y) = !Base.Order.lt(o, y, x)

struct Empty{T,O} <: PureFun.PFHeap{T,O}
    ord::O
end

struct NonEmpty{T,O} <: PureFun.PFHeap{T,O}
    x::T
    hs::Linked.List{NonEmpty{T,O}}
    ord::O
end

Heap{T,O} = Union{Empty{T,O}, NonEmpty{T,O}} where {T,O}

Heap{T}(o::Base.Order.Ordering=Base.Order.Forward) where T = Empty{T,typeof(o)}(o)

Base.isempty(::Empty) = true
Base.isempty(::NonEmpty) = false
Base.empty(h::Empty) = h
Base.empty(h::Heap) = Heap{eltype(h)}(ordering(h))

elem(h) = h.x
heaps(h) = h.hs
ordering(h::Heap) = h.ord
Base.minimum(h::NonEmpty) = elem(h)

Base.length(h::Empty) = 0
function Base.length(h::NonEmpty)
    isempty(heaps(h)) ? 1 : 1 + sum(length(h0) for h0 in heaps(h))
end

Base.merge(h::Heap, ::Empty) = h
Base.merge(::Empty, h::NonEmpty) = h
function Base.merge(h1::NonEmpty, h2::NonEmpty)
    x,y = elem(h1), elem(h2)
    o = ordering(h1)
    hs1, hs2 = heaps(h1), heaps(h2)
    leq(o, x, y) ? NonEmpty(x, cons(h2, hs1), o) : NonEmpty(y, cons(h1, hs2), o)
end

function PureFun.push(h::Heap{T,O}, x::T) where {T,O}
    o = ordering(h)
    merge(NonEmpty(x, Linked.List{NonEmpty{T,O}}(), o), h)
end

#merge_pairs(::Linked.Empty{T}) where T = Heap{T}()
function merge_pairs(h::Linked.Empty{NonEmpty{T,O}}, o::O) where {T,O}
    Heap{T}(o)
end
function merge_pairs(l, o)
    isempty(tail(l)) && return head(l)
    hs = l
    stack = empty(l)
    while !isempty(hs)
        isempty(tail(hs)) && return merge(head(hs), foldl(merge, stack))
        h1, h2, hs = head(hs), head(tail(hs)), tail(tail(hs))
        stack = pushfirst(stack, merge(h1, h2))
    end
    foldl(merge, stack)
end

PureFun.delete_min(h::NonEmpty) = merge_pairs(heaps(h), ordering(h))
#PureFun.tail(h::Heap) = delete_min(h)

Heap(iter::Heap) = iter
function Heap(iter, ord=Base.Order.Forward)
    reduce(push, iter, init = Heap{eltype(iter)}(ord))
end

end

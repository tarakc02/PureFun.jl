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

@doc raw"""

    Pairing.Heap{T}(o::Base.Order.Ordering=Base.Order.Forward)
    Pairing.Heap(iter, ord=Base.Order.Forward)

Pairing heaps ($\S{5.5}$):

> ... are one of those data structures that drive theoreticians crazy. On the
> one hand, pairing heaps are simple to implement and perform extremely well in
> practice. On the other hand, they have resisted analysis for over ten years!

`push`, `merge`, and `minimum` all run in $\mathcal{O}(1)$ worst-case time.
`popmin` can take $\mathcal{O}(n)$ time in the worst-case. However, it has
been proven that the amortized time required by `popmin` is no worse than
$\mathcal{O}(\log{}n)$, and there is an open conjecture that it is in fact
$\mathcal{O}(1)$. The amortized bounds here do *not* apply in persistent
settings. For heaps suited to persistent use-cases, see
[`PureFun.SkewBinomial.Heap`](@ref) and
[`PureFun.BootstrappedSkewBinomial.Heap`](@ref)

# Examples

```jldoctest
julia> using PureFun, PureFun.Pairing
julia> xs = [5, 3, 1, 4, 2];

julia> Pairing.Heap(xs)
5-element PureFun.Pairing.NonEmpty{Int64, Base.Order.ForwardOrdering}
1
2
3
4
5


julia> Pairing.Heap(xs, Base.Order.Reverse)
5-element PureFun.Pairing.NonEmpty{Int64, Base.Order.ReverseOrdering{Base.Order.ForwardOrdering}}
5
4
3
2
1


julia> empty = Pairing.Heap{Int}(Base.Order.Reverse);
julia> reduce(push, xs, init=empty)
5-element PureFun.Pairing.NonEmpty{Int64, Base.Order.ReverseOrdering{Base.Order.ForwardOrdering}}
5
4
3
2
1
```

"""
function Heap{T}(o::Base.Order.Ordering=Base.Order.Forward) where T
    Empty{T,typeof(o)}(o)
end

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

PureFun.popmin(h::NonEmpty) = merge_pairs(heaps(h), ordering(h))

Heap(iter::Heap) = iter
function Heap(iter, ord=Base.Order.Forward)
    reduce(push, iter, init = Heap{eltype(iter)}(ord))
end

end

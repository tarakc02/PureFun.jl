module BootstrappedSkewBinomial

using ..PureFun
const PrimHeap = PureFun.SkewBinomial.Heap

leq(o, x, y) = !Base.Order.lt(o, y, x)

# types {{{
elem(h) = h.x

struct Empty{T,O} <: PureFun.PFHeap{T,O}
    ord::O
end

struct NonEmpty{T,O} <: PureFun.PFHeap{T,O}
    x::T
    ord::O
    prim_heap::PrimHeap{ Union{Empty{T,O},NonEmpty{T,O}},
                         Base.Order.By{typeof(elem), O} }
end

Heap{T,O} = Union{Empty{T,O}, NonEmpty{T,O}} where {T,O<:Base.Order.Ordering}
HeapOfHeaps{T,O} = PrimHeap{
    Union{ Empty{T,O},NonEmpty{T,O} },
    Base.Order.By{typeof(elem), O}
   } where {T, O<:Base.Order.Ordering}

@doc raw"""
    BootstrappedSkewBinomial.Heap{T}(ord=Base.Order.Forward)
    BootstrappedSkewBinomial.Heap(iter, ord=Base.Order.Forward)

Section $\S{10.2.2}$ of *Purely Functional Data Structures* demonstrates how to
use structural abstraction to take a heap implementation with $\mathcal{O}(1)$
`push` and improve the running time of `merge` and `minimum` to
$\mathcal{O}(1)$. The `BootStrappedSkewBinomial.Heap` uses the technique on the
[`PureFun.SkewBinomial.Heap`](@ref).

"""
Heap{T}(ord=Base.Order.Forward) where T = Empty{T, typeof(ord)}(ord)

Base.empty(h::Heap{T,O}) where {T,O} = Empty{T,O}(ordering(h))
# }}}


ordering(heap::Heap) = heap.ord

Base.isempty(h::Empty) = true
Base.isempty(h::NonEmpty) = false

function Base.merge(h1::Heap{T,O}, h2::Heap{T,O}) where {T,O}
    isempty(h1) && return h2
    isempty(h2) && return h1
    o = ordering(h1)
    x1 = elem(h1)
    x2 = elem(h2)
    if leq(o, x1, x2)
        NonEmpty(x1, o, push(h1.prim_heap, h2))
    else
        NonEmpty(x2, o, push(h2.prim_heap, h1))
    end
end

function PureFun.push(heap::NonEmpty, x)
    merge(push(empty(heap), x), heap)
end

function PureFun.push(heap::Empty{T,O}, x) where {T,O}
    NonEmpty(x,
             ordering(heap),
             HeapOfHeaps{T,O}(Base.Order.By(elem, ordering(heap)))
            )
end

Base.minimum(h::NonEmpty) = elem(h)

function PureFun.delete_min(h::NonEmpty)
    isempty(h.prim_heap) && return empty(h)
    x  = elem(h)
    p = h.prim_heap
    y  = elem(minimum(p))
    p1 = minimum(p).prim_heap
    p2 = delete_min(p)
    NonEmpty(y, ordering(h), merge(p1, p2))
end

Heap(iter::Heap) = iter
function Heap(iter, ord=Base.Order.Forward)
    reduce(push, iter, init = Heap{eltype(iter)}(ord))
end

Base.IteratorSize(::Type{<:Heap}) = Base.SizeUnknown()

end

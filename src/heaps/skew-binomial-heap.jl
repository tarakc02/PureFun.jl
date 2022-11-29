module SkewBinomial

using ..PureFun, ..PureFun.Linked
using ..PureFun.Linked: List

leq(o, x, y) = !Base.Order.lt(o, y, x)

# types {{{
struct Node{T}
    r::Int
    x::T
    xs::List{T}
    c::List{Node{T}}
end

struct Heap{T,O} <: PureFun.PFHeap{T,O}
    trees::List{Node{T}}
    ord::O
end

@doc raw"""

    SkewBinomial.Heap{T}(o=Base.Order.Forward)
    SkewBinomial.Heap(iter, o=Base.Order.Forward)

The Skew Binomial Heap $\S{9.3.2}$ is a twist on the [Binomial
Heap](https://en.wikipedia.org/wiki/Binomial_heap): by basing tree sizes on
skew-binary (rather than binary) numbers, pushing a new element into a skew
binomial heap is worst-case $\mathcal{O}(1)$ (as opposed to
$\mathcal{O}(\log{}n)$ for binomial heaps). `merge`, `delete_min`, and
`minimum` are worst-case $\mathcal{O}(\log{}n)$. See also
[`BootstrappedSkewBinomial.Heap`](@ref), which uses structural abstraction to
improve `minimum` and `merge` to worst-case $\mathcal{O}(1)$

"""
function Heap{T}(o::Base.Order.Ordering=Base.Order.Forward) where T
    Heap(List{Node{T}}(), o)
end

Heap{T,O}(o) where {T,O} = Heap{T}(o)
# }}}

# accessors etc {{{
rank(n::Node) = n.r
root(n::Node) = n.x

Base.isempty(h::Heap) = isempty(trees(h))
Base.empty(h::Heap{T}) where T = Heap{T}(ordering(h))
trees(h::Heap) = h.trees
ordering(h::Heap) = h.ord
# }}}

# link/skewlink {{{

# note: I'm adding the Node's type parameter to the signature in order to
# preserve, e.g. if T is a union type
function link(t1::Node{T}, t2::Node{T}, o::Base.Order.Ordering) where T
    leq(o, root(t1), root(t2)) ?
    Node{T}(1+rank(t1), root(t1), t1.xs, cons(t2, t1.c)) :
    Node{T}(1+rank(t1), root(t2), t2.xs, cons(t1, t2.c))
end

function skewlink(x, t1::Node{T}, t2::Node{T}, o::Base.Order.Ordering) where T
    n = link(t1, t2, o)
    r = rank(n)
    y = root(n)
    ys = n.xs
    c = n.c
    leq(o, x, y) ? Node{T}(r, x, cons(y, ys), c) : Node{T}(r, y, cons(x, ys), c)
end
# }}}

# inserting elements {{{
function PureFun.push(h::Heap, x)
    ord = ordering(h)
    ts = trees(h)
    Heap(_push(ts, x, ord), ord)
end

function _push(ts::Linked.Empty{Node{T}}, x, o) where T
    cons(Node(0, x, List{T}(), List{Node{T}}()), ts)
end

function _push(ts::Linked.List{Node{T}}, x, o) where T
    if isempty(tail(ts)) || rank(ts[1]) != rank(ts[2])
        return cons(Node(0, x, List{T}(), List{Node{T}}()), ts)
    end
    t1, t2 = ts[1], ts[2]
    rest = tail(tail(ts))
    cons(skewlink(x, t1, t2, o), rest)
end
# }}}

normalize(ts, o) = isempty(ts) ? ts : ins_tree(head(ts), tail(ts), o)

_merge(ts1, ts2, o) = merge_trees(normalize(ts1, o), normalize(ts2, o), o)

Base.merge(h1, h2) = Heap(_merge(trees(h1), trees(h2), ordering(h1)),
                          ordering(h2))

function (ins_tree(t1::N, trees, o)::List{N}) where N
    isempty(trees) && return cons(t1, trees)
    t2 = head(trees)
    ts = tail(trees)
    rank(t1) < rank(t2) ? cons(t1, trees) : ins_tree(link(t1, t2, o), ts, o)
end

function merge_trees(ts1, ts2, o)
    isempty(ts2) && return ts1
    isempty(ts1) && return ts2
    t1, _ts1... = ts1
    t2, _ts2... = ts2
    if rank(t1) < rank(t2)
        cons(t1, merge_trees(_ts1, ts2, o))
    elseif rank(t2) < rank(t1)
        cons(t2, merge_trees(ts1, _ts2, o))
    else
        ins_tree(link(t1, t2, o), merge_trees(_ts1, _ts2, o), o)
    end
end

function remove_min_tree(trees::Linked.NonEmpty, o)
    t, ts... = trees
    isempty(ts) && return t, ts
    _t, _ts = remove_min_tree(tail(trees), o)
    leq(o, root(t), root(_t)) ? (t, ts) : (_t, cons(t, _ts))
end

function Base.minimum(h::Heap)
    root(first( remove_min_tree(trees(h), ordering(h)) ))
end

function PureFun.delete_min(h::Heap)
    o = ordering(h)
    n, ts2 = remove_min_tree(trees(h), o)
    x = root(n)
    xs = n.xs
    ts1 = n.c
    Heap(insert_all(xs, _merge(reverse(ts1), ts2, o), o), o)
end

function (insert_all(xs, ts::L, o)::L) where L
    isempty(xs) ? ts : insert_all(tail(xs), _push(ts, head(xs), o), o)
end

Heap(iter::Heap) = iter
function Heap(iter, ord=Base.Order.Forward)
    reduce(push, iter, init = Heap{eltype(iter)}(ord))
end

Base.IteratorSize(::Type{<:Heap}) = Base.SizeUnknown()
Base.eltype(::Type{<:Heap{T}}) where T = T

end

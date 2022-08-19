module RandomAccess

using ..PureFun
using ..PureFun.Linked

# type definitions {{{
struct Leaf{α}
    x::α
end

struct Node{α}
    x::α
    t1::Union{ Node{α},Leaf{α} }
    t2::Union{ Node{α},Leaf{α} }
end

struct Tree{α}
    w::Int
    t::Union{ Node{α},Leaf{α} }
end

struct List{α} <: PureFun.PFList{α}
    rl::Linked.List{ Tree{α} }
end

# }}}

# accessors and utilities {{{
isleaf(tree::Tree) = tree.t isa Leaf
isleaf(leaf::Leaf) = true
isleaf(node::Node) = false
Base.isempty(list::List) = isempty(list.rl)
Base.empty(list::List{α}) where α = List(empty(list.rl))

elem(tree::Tree) = tree.t.x
elem(node::Node) = node.x
elem(leaf::Leaf) = leaf.x
weight(tree::Tree) = tree.w
tree(t::Tree) = t.t

elem(xs::List) = elem(tree(xs))
weight(xs::List) = weight(head(xs.rl))
tree(xs::List) = tree(head(xs.rl))

sing(x) = Tree(1, Leaf(x))
# }}}

# PFList API {{{
"""
    RandomAccess.List{T}()
    RandomAccess.List(iter)

A `RandomAccess.List` supports the usual list operations, and additionally
provides access to get or set the *k*th index in O(log(k)) time, rather than
O(k)

# Parameters
`T::Type` element type (inferred if creating from `iter`)

# Examples
```@jldoctest
julia> rl = PureFun.RandomAccess.List(1:1_000)
1
2
3
4
5
6
7
...


julia> rl[937]
937
```
"""
List{α}() where α = List(Linked.List{ Tree{α} }())
List(iter)  = foldr( cons, iter; init=List{eltype(iter)}() )

function PureFun.cons(x, xs::List)
    isempty(xs) && return List(cons(sing(x), xs.rl))
    ts2 = tail(xs.rl)
    isempty(ts2) && return List(cons(sing(x), xs.rl))
    w1, w2 = weight(xs.rl[1]), weight(xs.rl[2])
    if w1 == w2
        List(cons( Tree( 1+w1+w2, Node(x, tree(xs.rl[1]), tree(xs.rl[2])) ), tail(ts2) ))
    else
        List(cons(sing(x), xs.rl))
    end
end

PureFun.head(ts::List) = elem(head(ts.rl))
PureFun.tail(ts::List) = _tail(head(ts.rl), tail(ts.rl))

function _tail(h::Tree, ts)
    isleaf(h) && return List(ts)
    w, node = weight(h), tree(h)
    node isa Leaf && return List(ts)
    w2 = div(w,2)
    List(cons( Tree(w2, node.t1), cons(Tree(w2, node.t2), ts) ))
end

function Base.length(ts::List)
    isempty(ts) && return 0
    len = 0
    rl = ts.rl
    while !isempty(rl)
        s = weight(head(rl))
        len += s
        rl = tail(rl)
    end
    return len
end

# }}}

# lookup {{{
function lookup(xs::List, i::Integer)
    w = weight(xs)
    rl = xs.rl
    while i >= w && !isempty(rl)
        rl = tail(rl)
        i -= w
        w = weight(head(rl))
    end
    lookup_tree(w,i,head(rl))
end

function lookup_tree(w,i,t::Tree)
    t = tree(t)
    while i > 0
        isleaf(t) && throw(BoundsError(t, i))
        w = div(w, 2)
        if i <= w
            i -= 1
            t = t.t1
        else
            i = i-1-w
            t = t.t2
        end
    end
    return elem(t)
end


Base.getindex(xs::List, i::Integer) = lookup(xs, i-1)
# }}}

# update {{{
function update(trees, i::Integer, y)
    w = weight(head(trees))
    t = tree(head(trees))
    if i<w
        cons(Tree(w, update_tree(w, i, y, t)), tail(trees) )
    else
        cons(head(trees), update(tail(trees), i-w, y))
    end
end

Base.setindex(xs::List, y, i) = List(update(xs.rl, i-1, y))

update_tree(w, i, y, t::Leaf) = i == 0 ? Leaf(y) : throw(BoundsError(t, i))

function update_tree(w, i, y, t::Node)
    i == 0 && return Node(y, t.t1, t.t2)
    w2 = div(w,2)
    if i <= w2
        return Node(elem(t), update_tree(w2, i-1, y, t.t1), t.t2)
    else
        return Node(elem(t), t.t1, update_tree(w2, i-1-w2, y, t.t2))
    end
end
# }}}

function get_type(f, xs::List)
    typeof( f(head(xs)) )
end

function Base.map(f, xs::List)
    rl = xs.rl
    T = get_type(f, xs)
    List(_map(f, rl, T))
end

# maybe in some cases we want to do the tail map in parallel (e.g. with another
# @spawn)
function _map(f, rl, T)
    func(chunk) = maptree(f, chunk)
    mapfoldr(func, cons, rl, init=Linked.List{Tree{T}}())
#    isempty(rl) ?
#    Linked.List{Tree{T}}() :
#    cons(maptree(f, head(rl)),
#         _map(f, tail(rl), T))
#
end

function maptree(f, tree::Tree)
    w = weight(tree)
    #Tree(w, pmapnode(f, tree.t, w))
    Tree(w, mapnode(f, tree.t))
end

# whether/when to multi-thread depends on how expensive f(::eltype(node)) is
function pmapnode(f, node::Node, w)
    w < 1000 && return mapnode(f, node)
    t1 = Threads.@spawn pmapnode(f, node.t1, (w-1)/2)
    t2 = pmapnode(f, node.t2, (w-1)/2)
    Node( f(elem(node)), fetch(t1), fetch(t2) )
end

function mapnode(f, node::Node)
    Node( f(elem(node)),
          mapnode(f, node.t1),
          mapnode(f, node.t2) )
end

function mapnode(f, leaf::Leaf)
    Leaf(f(elem(leaf)))
end

pmapnode(f, leaf::Leaf, w) = mapnode(f, leaf)

struct Init end

function Base.mapreduce(f, op, xs::List; init=Init())
    isempty(xs) && init isa Init && return Base.reduce_empty(op, eltype(xs))
    func(tree) = _mapreduce(f, op, tree.t)
    out = mapreduce(func, op, xs.rl)
    init isa Init ? out : op(init, out)
end

_mapreduce(f, op, t::Leaf) = Base.reduce_first(op, f(elem(t)))

function _mapreduce(f, op, t::Node)
    op( op(f(elem(t)), _mapreduce(f, op, t.t1)), _mapreduce(f, op, t.t2) )
end

end

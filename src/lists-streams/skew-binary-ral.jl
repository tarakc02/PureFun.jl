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

Tree{α} = Union{ Node{α},Leaf{α} } where α
E{α} = Linked.Empty{ Tuple{Int64, Tree{α} }} where α
NE{α} = Linked.NonEmpty{ Tuple{Int64, Tree{α} }} where α

List{α} = Union{ E{α},NE{α} } where α
Base.eltype(::List{α}) where α = α
# }}}

# accessors and utilities {{{
isleaf(t::Tree) = false
isleaf(::Leaf) = true
elem(t::Tree) = t.x
elem(t::Tuple{Int64, Tree}) = t[2].x
isempty(::E) = true
isempty(::NE) = false

sing(x) = (1, Leaf(x))
weight(xs) = (xs.head)[1]
tree(xs) = (xs.head)[2]
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
List{α}() where α = E{α}()
List(iter)  = foldr( cons, iter; init=E{eltype(iter)}() )

PureFun.cons(x::α, ts::E{α}) where α = cons(sing(x), ts)
function PureFun.cons(x::α, ts::NE{α}) where α 
    ts2 = ts.tail
    isempty(ts2) && return cons(sing(x), ts)
    w1, w2 = weight(ts), weight(ts.tail)
    if w1 == w2
        cons(( 1+w1+w2, Node(x, tree(ts), tree(ts.tail)) ), ts2.tail)
    else
        cons(sing(x), ts)
    end
end

PureFun.head(ts::NE) = elem(ts.head)
PureFun.tail(ts::NE) = _tail(ts.head, ts.tail)
_tail(h::Tuple{ Int64, Leaf }, ts) = ts
function _tail(h::Tuple{ Int64, Node }, ts)
    w, node = h
    w2 = div(w,2)
    cons( (w2, node.t1), cons((w2, node.t2), ts) )
end

#Base.IteratorSize(::List) = Base.HasLength()
Base.length(ts::E) = 0
function Base.length(ts::NE)
    len = 0
    while !isempty(ts)
        s = ts.head[1]
        len += s
        ts = ts.tail
    end
    return len
end

# }}}

# lookup {{{
function lookup(xs::NE, i::Integer)
    w = weight(xs)
    while i >= w && !isempty(xs)
        xs = xs.tail
        i -= w
        w = weight(xs)
    end
    lookup_tree(w,i,tree(xs))
end

#function lookup_tree(w,i,t::Leaf)
#    i == 0 ? elem(t) : throw(BoundsError(t, i))
#end

function lookup_tree(w,i,t::Tree)
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


Base.getindex(xs::NE, i::Integer) = lookup(xs, i-1)
# }}}

# update {{{
function update(xs::NE, i::Integer, y)
    w = weight(xs)
    t = tree(xs)
    i<w ? cons((w, update_tree(w, i, y, t)), tail(xs) ) : cons((w,t), update(xs.tail, i-w, y))
end

PureFun.setindex(xs::NE, i, y) = update(xs, i-1, y)

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

end

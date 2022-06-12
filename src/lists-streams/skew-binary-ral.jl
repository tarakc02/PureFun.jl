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
#List{α}() where α = E{α}()
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

PureFun.setindex(xs::List, i, y) = List(update(xs.rl, i-1, y))

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

# iteration {{{

#struct RalIterator{T}
#    rl::Linked.List{ Tree{T} }
#    curtree::Union{ Node{T},Leaf{T} }
#    back::Linked.List{ Node{T} }
#end
#
#function Base.iterate(xs::List{T}) where{T}
#    it = RalIterator(
#        xs.rl,
#        tree(head(xs.rl)),
#        Linked.List{ Node{T} }()
#    )
#    head(xs), it
#end
#
#function Base.iterate(xs::List, it::RalIterator)
#    trees = it.rl
#    cur = it.curtree
#    back = it.back
#    # continue down the current branch if not at end
#    if !isleaf(cur)
#        new_it = RalIterator(trees, cur.t1, cons(cur, back))
#        return elem(cur.t1), new_it
#    end
#    # backtrack up the tree until there's an unvisited right turn
#    while !isempty(back) && cur === head(back).t2
#        cur = head(back)
#        back = tail(back)
#    end
#    # if the current tree is exhausted, move to the next one
#    if isempty(back)
#        trees = tail(trees)
#        isempty(trees) && return nothing
#        cur = tree(head(trees))
#        new_it = RalIterator(trees, cur, empty(back))
#        return elem(cur), new_it
#    end
#    cur = head(back).t2
#    new_it = RalIterator( trees, cur, back )
#    return elem(cur), new_it
#end

# }}}

end

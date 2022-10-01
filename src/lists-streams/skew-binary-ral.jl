module RandomAccess

using ..PureFun
using ..PureFun.Linked
using AbstractTrees

include("skewbin-partition-iter.jl")

# type definitions {{{
struct Leaf{α}
    x::α
end

struct Node{α}
    x::α
    t1::Union{ Node{α},Leaf{α} }
    t2::Union{ Node{α},Leaf{α} }
end

Tree{α} = Union{ Node{α},Leaf{α} }

struct Digit{α}
    w::Int
    t::Tree{α}
end

struct List{α} <: PureFun.PFList{α}
    rl::Linked.List{ Digit{α} }
    List{α}(xs) where α = new{α}(xs)
end

# }}}

# accessors and utilities {{{
digits(xs::List) = xs.rl

weight(digit::Digit) = digit.w
tree(d::Digit) = d.t

isleaf(digit::Digit) = tree(digit) isa Leaf
isleaf(leaf::Leaf) = true
isleaf(node::Node) = false

Base.isempty(list::List) = isempty(digits(list))
Base.empty(list::List) = List(empty(digits(list)))
Base.empty(list::List, eltype) = List(empty(digits(list), Digit{eltype}))

elem(digit::Digit) = elem(tree(digit))
elem(node::Node) = node.x
elem(leaf::Leaf) = leaf.x

sing(x, T) = Digit(1, Leaf{T}(x))

Base.length(d::Digit) = weight(d)
Base.lastindex(d::Digit) = length(d)
Base.firstindex(d::Digit) = 1
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
List{α}() where α = List{α}(Linked.List{ Digit{α} }())
List(iter::List)  = iter
List(rl::Linked.List{Digit{α}}) where α = List{α}(rl)
#List(iter)  = foldr( cons, iter; init=List{eltype(iter)}() )
List(iter) = makelist(iter)

function PureFun.cons(x, xs::List)
    isempty(xs) && return List(cons(sing(x, eltype(xs)), digits(xs)))
    d = digits(xs)
    _cons(x, d, tail(d), eltype(xs))
end

function _cons(x, d, ds, T)
    isempty(ds) && return List(cons(sing(x, T), d))
    w1, w2 = weight(head(d)), weight(head(ds))
    if w1 == w2
        List(cons(Digit(1+w1+w2,
                        Node(x, tree(head(d)), tree(head(ds))) ),
                  tail(ds) ))
    else
        List(cons(sing(x, T), d))
    end
end

PureFun.head(ts::List) = elem(head(digits(ts)))
PureFun.tail(ts::List) = _tail(head(digits(ts)), tail(digits(ts)))

function _tail(h::Digit, ts)
    isleaf(h) && return List(ts)
    w, node = weight(h), tree(h)
    node isa Leaf && return List(ts)
    w2 = div(w,2)
    List(cons( Digit(w2, node.t1), cons(Digit(w2, node.t2), ts) ))
end

Base.length(ts::List) = mapreduce(weight, +, digits(ts), init = 0)

# }}}

# lookup {{{
function lookup(xs::List, i::Integer)
    rl = digits(xs)
    w = weight(head(rl))
    while i >= w && !isempty(rl)
        rl = tail(rl)
        i -= w
        w = weight(head(rl))
    end
    lookup_tree(w,i,head(rl))
end

function lookup_tree(w,i,t::Digit)
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
Base.getindex(d::Digit, i::Integer) = lookup_tree(weight(d), i-1, d)
# }}}

# update {{{
function update(trees, i::Integer, y)
    w = weight(head(trees))
    t = tree(head(trees))
    if i<w
        cons(Digit(w, update_tree(w, i, y, t)), tail(trees) )
    else
        cons(head(trees), update(tail(trees), i-w, y))
    end
end

Base.setindex(xs::List, y, i) = List(update(digits(xs), i-1, y))
function Base.setindex(d::Digit, y, i)
    @boundscheck i < weight(d) || throw(BoundsError(d, i))
    Digit(weight(d), update_tree(weight(d), i, y, d))
end

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

# specializations for map + mapreduce {{{
function get_type(f, xs::List)
    #Base.@default_eltype(Iterators.map(f, xs))
    isempty(xs) ?
        PureFun.infer_return_type(f, xs) :
        typeof(f(first(xs)))
end

function Base.map(f, xs::List)
    rl = digits(xs)
    T = get_type(f, xs)
    List(_map(f, rl, T))
end

function _map(f, rl, T)
    func(chunk) = maptree(f, chunk)
    #map(func, rl)::Linked.List{Digit{T}}
    mapfoldr( func, cons, rl, init=Linked.List{Digit{T}}() )
end

function maptree(f, tree::Digit)
    w = weight(tree)
    #Digit(w, pmapnode(f, tree.t, w))
    Digit(w, mapnode(f, tree.t))
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
    isempty(xs) && return init
    func(tree) = _mapreduce(f, op, tree.t)
    out = mapreduce(func, op, digits(xs))
    init isa Init ? out : op(init, out)
end

_mapreduce(f, op, t::Leaf) = Base.reduce_first(op, f(elem(t)))

function _mapreduce(f, op, t::Node)
    op( op(f(elem(t)), _mapreduce(f, op, t.t1)), _mapreduce(f, op, t.t2) )
end

# }}}

# iteration {{{
function Base.iterate(xs::List)
    isempty(xs) && return nothing
    ds = digits(xs)::Linked.NonEmpty{Digit{eltype(xs)}}
    d = head(ds)
    tr = tree(d)
    trs = cons(tr, Linked.List{Tree{eltype(xs)}}())
    iterate(xs, (trs, ds))
end

function Base.iterate(xs::List, state)
    trs, ds = state[1], state[2]
    if isempty(trs)
        ds = tail(ds)
        isempty(ds) && return nothing
        d = head(ds)
        tr = tree(d)
        trs = cons(tr, trs)
    end
    tr = head(trs)
    rest = tr isa Leaf ? tail(trs) : cons(tr.t1, cons(tr.t2, tail(trs)))
    elem(tr), (rest, ds)
end
# }}}

# AbstractTrees interface for digits {{{
AbstractTrees.children(t::Digit) = children(tree(t))
AbstractTrees.children(t::Node) = (t.t1, t.t2)
AbstractTrees.children(t::Leaf) = ()

AbstractTrees.childrentype(::Type{<:Digit{T}}) where T = Tuple{ Tree{T},Tree{T} }
AbstractTrees.childrentype(::Type{<:Node{T}}) where T = Tuple{ Tree{T},Tree{T} }
AbstractTrees.childrentype(::Type{<:Leaf}) = Tuple{}

AbstractTrees.nodevalue(t::Union{Tree,Digit}) = elem(t)
AbstractTrees.nodevaluetype(t::Union{Tree{T},Digit{T}}) where T = T

AbstractTrees.NodeType(::Type{<:Tree{T}}) where {T} = HasNodeType()
AbstractTrees.NodeType(::Type{<:Digit{T}}) where {T} = HasNodeType()
AbstractTrees.nodetype(::Type{<:Tree{T}}) where {T} = Tree{T}
AbstractTrees.nodetype(::Type{<:Digit{T}}) where {T} = Tree{T}

function Base.show(io::IO, ::MIME"text/plain", d::Digit)
    AbstractTrees.print_tree(io, d)
end
function Base.show(io::IO, d::Digit{T}) where T
    print(io, "Digit{$T}($(weight(d)))")
    print(io, " ", d[1])
    if length(d) > 1 print(" ... ", d[end]) end
end
# }}}

end

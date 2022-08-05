module RedBlack

using ..PureFun
using ..PureFun.Linked

include("basics.jl")
include("insert.jl")
include("traversal.jl")
include("delete.jl")
include("from-sorted.jl")

# pretty printing {{{
function Base.show(::IO, ::MIME"text/plain", t::E{T}) where {T} 
    println("an empty rb-tree of type $(typeof(t))")
end

function Base.show(::IO, ::MIME"text/plain", t::NonEmpty{T}) where {T} 
    len = length(t)
    n = 3
    it = mintrail(t)
    while !isempty(it) && n > 0
        println(elem(head(it)))
        it = next_inorder(it)
        n -= 1
    end
    if isempty(it) return nothing end
    if (len-3) > 3 println("⋮") end
    rit = maxtrail(t)
    rn = min(len-4, 2)
    while !isempty(rit) && rn > 0
        rit = prv_inorder(rit)
        rn -= 1
    end
    while !isempty(rit) && rn <= 3
        println(elem(head(rit)))
        rit = next_inorder(rit)
        rn += 1
    end
end
# }}}

# PFDict interface {{{
dictkey(p::Pair) = p.first
dictkey(x) = x
dictorder(o) = Base.Order.By(dictkey, o)

struct RBDict{O,K,V} <: PureFun.PFDict{K,V} where O
    t::NonRed{Pair{K,V}, Base.Order.By{typeof(PureFun.RedBlack.dictkey), O}}
end

function RBDict{K,V}(ord=Base.Order.Forward) where {K,V}
    o = dictorder(ord)
    t = E{ Pair{K,V} }(o)
    RBDict{typeof(ord),K,V}(t)
end

function RBDict{O,K,V}() where {O,K,V}
    o = dictorder(O())
    t = E{ Pair{K,V} }(o)
    RBDict{O,K,V}(t)
end


RBDict(t::NonRed{ Pair{K,V},O }) where {K,V,O} = RBDict{O,K,V}(t)

function RBDict(iter, o::Ordering=Forward)
    t = RB(iter, dictorder(o))
    RBDict(t)
end

Base.isempty(d::RBDict) = isempty(d.t)

function Base.empty(d::RBDict{O,K,V}) where {O,K,V}
    t = empty(d.t)
    RBDict{O,K,V}(t)
end

Base.setindex(d::RBDict, v, k) = RBDict(insert(d.t, Pair(k,v)))
val(p) = elem(p).second
Base.get(d::RBDict, k, default) = traverse(d.t, k, val, x -> default)
Base.get(f::Function, d::RBDict, k) = traverse(d.t, k, val, x -> f())

Base.iterate(d::RBDict) = iterate(d.t)
Base.iterate(d::RBDict, state) = iterate(d.t, state)
Base.length(d::RBDict) = length(d.t)

Iterators.reverse(d::RBDict) = Iterators.reverse(d.t)

function Base.show(i::IO, m::MIME"text/plain", s::RBDict)
    show(i,m,s.t)
end
# }}}

# PFSet interface {{{
struct RBSet{O,T} <: PureFun.PFSet{T} where O
    t::NonRed{T,O}
end

function RBSet{T}(ord=Base.Order.Forward) where {T}
    t = E{T}(ord)
    RBSet{typeof(ord),T}(t)
end

function RBSet(iter, o::Ordering=Forward)
    t = RB(iter, o)
    RBSet(t)
end

Base.isempty(s::RBSet) = isempty(s.t)

function Base.empty(s::RBSet{O,T}) where {O,T}
    t = empty(s.t)
    RBSet{O,T}(t)
end

PureFun.push(s::RBSet, x) = RBSet(insert(s.t, x))
Base.in(s::RBSet, x) = traverse(s.t, x, return_true, return_false)

Base.iterate(s::RBSet) = iterate(s.t)
Base.iterate(s::RBSet, state) = iterate(s.t, state)
Base.length(s::RBSet) = length(s.t)
Iterators.reverse(d::RBSet) = Iterators.reverse(s.t)

function Base.show(i::IO, m::MIME"text/plain", s::RBSet)
    show(i,m,s.t)
end

# }}}

end

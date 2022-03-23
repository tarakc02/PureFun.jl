module RedBlack

using PureFun
using PureFun.Lists.Linked

include("basics.jl")
include("insert.jl")
include("traversal.jl")
include("delete.jl")

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

dictkey(p::Pair) = p.first
dictkey(x) = x
dictorder(o) = Base.Order.By(dictkey, o)

struct RBDict{K,V,O,T} <: PureFun.PFDict{K,V} where { T <: NonRed{Pair{K,V}} }
    t::T
end

function RBDict{K,V}(ord=Base.Order.Forward) where {K,V}
    o = dictorder(ord)
    t = E{ Pair{K,V} }(o)
    RBDict{K,V,typeof(ord), typeof(t)}(t)
end

RBDict{O}(t::NonRed{ Pair{K,V} }) where {K,V,O} = RBDict{K,V,O,typeof(t)}(t)

function RBDict(iter, o::Ordering=Forward)
    t = RB(iter, dictorder(o))
    RBDict{typeof(o)}(t)
end

PureFun.setindex(d::RBDict, k, v) = RBDict(insert(d.t, Pair(k,v)))
PureFun.insert(d::RBDict, p::Pair) = RBDict(insert(d.t, p))
val(p) = elem(p).second
Base.get(d::RBDict, k, default) = traverse(d.t, k, val, x -> default)
Base.get(f::Function, d::RBDict, k) = traverse(d.t, k, val, x -> f())

Base.iterate(d::RBDict) = iterate(d.t)
Base.iterate(d::RBDict, state) = iterate(d.t, state)
Base.length(d::RBDict) = length(d.t)

function Base.show(i::IO, m::MIME"text/plain", s::RBDict)
    show(i,m,s.t)
end


end

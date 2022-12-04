module Association

using PureFun
using PureFun.Linked

abstract type Map{K,V} <: PureFun.PFDict{K,V} end

## not using PureFun.VectorCopy.List here right now, b/c want to use various
## vector/abstract array methods, e.g. `searchsortedfirst`. this would (i
## think?) work fine if PFLists inherit from AbstractArray, and if
## VectorCopyList had a function that wraps whatever vec operations you want in
## a copy and vectorycopylist constructor
##
## Q2: why not just have a Base.Dict with copying,
## analagous to VectorCopy.List for lists?
#struct VectorList{K,V} <: Map{K,V}
#    pairs::Vector{Pair{K,V}}
#    VectorList{K,V}() where {K,V} = new{K,V}(Pair{K,V}[])
#    VectorList{K,V}(v::Vector{Pair{K,V}}) where {K,V} = new{K,V}(v)
#    VectorList(v::Vector{Pair{K,V}}) where {K,V} = new{K,V}(v)
#    function VectorList(iter)
#        prs = collect(iter)
#        sort!(prs)
#        VectorList(prs)
#    end
#end

@doc raw"""
    Association.List{K,V}()
    Association.List(iter)

A dictionary implemented as a linked list of pairs. Adding/updating new items
is very fast, but lookups can be as bad as $\mathcal{O}(n)$. Almost identical
to `Base.ImmutableDict`, but with a few extra bells and whistles to conform the
expected interface for [`PureFun.PFDict`](@ref).

# Examples

```jldoctest
julia> using PureFun, PureFun.Association

julia> Association.List(k => Char(k) for k in rand(UInt16, 5))
PureFun.Association.List{UInt16, Char} with 5 entries:
  0x5d5d => '嵝'
  0x6ab9 => '檹'
  0x4eb0 => '亰'
  0xd55c => '한'
  0xd018 => '퀘'
```
"""
struct List{K,V} <: Map{K,V}
    pairs::PureFun.Linked.List{Pair{K,V}}
    List{K,V}() where {K,V} = new{K,V}(Linked.List{Pair{K,V}}())
    List(l::Linked.List{Pair{K,V}}) where {K,V} = new{K,V}(l)
    function List(iter)
        P = Base.@default_eltype(iter)
        P <: Pair || throw(MethodError(List, iter))
        prs = foldl(pushfirst, iter, init = Linked.List{P}())
        List(prs)
    end
end

Base.isempty(al::Map) = isempty(al.pairs)

#Base.length(al::VectorList) = length(al.pairs)
Base.length(l::List) = isempty(l) ? 0 : sum(1 for _ in l)

#Base.iterate(d::VectorList) = iterate(d.pairs)
#Base.iterate(d::VectorList, state) = iterate(d.pairs, state)

function Base.iterate(l::List)
    isempty(l) && return nothing
    st = PureFun.RedBlack.RBSet{keytype(l)}()
    el = first(l.pairs)
    st = push(st, el.first)
    el, (l.pairs, st)
end

function Base.iterate(ll::List, state)
    l, st = popfirst(state[1]), state[2]
    isempty(l) && return nothing
    while first(l).first ∈ st
        l = popfirst(l)
        isempty(l) && return nothing
    end
    el = first(l)
    st = push(st, el.first)
    first(l), (l, st)
end

#Base.empty(al::VectorList) = VectorList(empty(al.pairs))
Base.empty(al::List) = List(empty(al.pairs))

Base.setindex(l::List, v, k) = List(Pair(k,v) ⇀ l.pairs)

# what is the right way to do this?
#_key(p::Pair) = p.first
#_key(x) = x

# credit https://stackoverflow.com/questions/25678112/insert-item-into-a-sorted-list-with-julia-with-and-without-duplicates
#function Base.setindex(l::VectorList{K,V}, v, k) where {K,V}
#    p = Pair(k,v)
#    newpairs = copy(l.pairs)
#    ix = searchsortedfirst(newpairs, p, by = _key)
#    insert!(newpairs, ix, p)
#    VectorList{K,V}(newpairs)
#end
#
#function Base.get(v::VectorList, k, default)
#    pairs = v.pairs
#    ind = searchsortedfirst(pairs, k, by = _key)
#    (ind > lastindex(pairs) || pairs[ind].first != k) ?
#        default :
#        pairs[ind].second
#end

function PureFun.get(d::List, k, default)
    pairs = d.pairs
    isempty(pairs) && return default
    for kv in pairs
        kv.first == k && return kv.second
    end
    default
end

PureFun.push(d::Map, p::Pair) = PureFun.setindex(d, p[2], p[1])

end

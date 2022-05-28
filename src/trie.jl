module Tries

using PureFun
using PureFun: PFDict, setindex

const List = PureFun.Linked.List
const Queue = PureFun.Bootstrapped.Queue


Option{T} = Union{Some{T}, Nothing} where T

struct Trie{K,V,D} <: PFDict{K,V} where {D <: PFDict}
    v::Option{V}
    m::D
end

# Trie keys should be iterators over some simple key type,
# use `simpletype` to get the inner key type from the outer type
# e.g. String -> Char, PFList{T} -> T
simpletype(t::Trie{K,V,D}) where {K,V,D} = eltype(K)

function Trie{K,V}(DictType=PureFun.RedBlack.RBDict) where {K,V} 
    k = eltype(K)
    edgemap = DictType{k,Trie{K,V}}()
    Trie{K,V,typeof(edgemap)}(nothing, edgemap)
end

Trie{K,V}(v::Option{V}, m::M) where {K,V,M} = Trie{K,V,M}(v,m)

Trie{K}(v::Option{V}, m::M) where {K,V,M} = Trie{K,V,M}(v,m)

Base.isempty(t::Trie) = isnothing(t.v) && isempty(t.m)
Base.empty(t::Trie{K,V}) where {K,V} = Trie{K,V}(nothing, empty(t.m))
Base.IteratorSize(::Trie) = Base.SizeUnknown()

function Base.get(t::Trie, keys, default)
    isempty(keys) && return default
    for k in keys
        isempty(t) && return default
        t = get(t.m, k, empty(t))
    end
    isnothing(t.v) ? default : something(t.v)
end

function PureFun.setindex(trie::Trie{K,V}, keys, x) where {K,V}
    isempty(keys) && return Trie{typeof(keys)}(Some(x), trie.m)
    k,ks... = keys
    t = get(trie.m, k, empty(trie))
    tprime = setindex(t, K(ks), x)
    Trie{K,V}(trie.v, setindex(trie.m, k, tprime));
end

PureFun.insert(t::Trie, p::Pair) = setindex(t, p[1], p[2])

function Trie(iter)
    peek = first(iter)
    peek isa Pair || return MethodError(Trie, iter)
    K, V = typeof(peek[1]), typeof(peek[2])
    reduce(insert, iter, init=Trie{K,V}())
end

#function Base.iterate(t::Trie)
#    K = keytype(t)
#    buffer = List{simpletype(t)}()
#    edgestates = List{Any}()
#    if isnothing(t.v)
#        iterate(t, (edgestates, buffer))
#    else
#        kv = K(reverse!(collect(buffer))) => something(t.v)
#        kv, (edgestates, buffer)
#    end
#end

function Base.iterate(t::Trie)
    K = keytype(t)
    buffer = List{simpletype(t)}()
    edgestates = List{Any}()
    edgestates = isnothing(t.v) ? edgestates : cons((t.m, ()), edgestates) 
    while isnothing(t.v)
        edgeiter = iterate(t.m)
        isnothing(edgeiter) && return nothing
        e, st = edgeiter
        edgestates = cons((t.m, st), edgestates)
        buffer = cons(e[1], buffer)
        t = e[2]
    end
    kv = K(reverse!(collect(buffer))) => something(t.v)
    kv, (edgestates, buffer)
end

function Base.iterate(t::Trie, state)
    K = keytype(t)
    edgestates, buffer = state
    isempty(edgestates) && return nothing

    edges, edgestate = head(edgestates)
    edgeiter = edgestate === () ? iterate(edges) : iterate(edges, edgestate)

    # if the current edgemap is exhausted, go up a level and advance an edge
    while isnothing(edgeiter)
        edgestates = tail(edgestates)
        isempty(edgestates) && return nothing
        buffer = tail(buffer)
        edges, edgestate = head(edgestates)
        edgeiter = edgestate === () ? iterate(edges) : iterate(edges, edgestate)
    end

    edge, edgestate = edgeiter
    trie = edge[2]
    edgestates = cons((edges, edgestate), tail(edgestates))
    buffer = cons(edge[1], isempty(buffer) ? buffer : tail(buffer))

    # now descend to the first valid key
    while isnothing(trie.v)
        edgeiter = iterate(trie.m)
        isnothing(edgeiter) && return nothing
        edge, edgestate = edgeiter
        edgestates = cons((trie.m, edgestate), edgestates)
        buffer = cons(edge[1], buffer)
        trie = edge[2]
    end
    kv = K(reverse!(collect(buffer))) => something(trie.v)
    kv, (edgestates, buffer)
end

end

using PureFun
using .Tries: Trie

using Random

ks = [randstring("abcdefg", rand(8:15)) for _ in 1:1000]
vs = [rand(Int8) for _ in 1:1000]

ks = ["tarak", "rashmi", "shah"]
vs = [1, 2, 3]



t = Trie(k => v for (k,v) in zip(ks, vs));
d = Dict(k => v for (k,v) in zip(ks, vs));
rb = PureFun.RedBlack.RBDict(k => v for (k,v) in zip(ks, vs));

using BenchmarkTools
@btime $rb["abfbbdgbagaec"]
@btime $d["abfbbdgbagaec"]
@btime $t["abfbbdgbagaec"]

for kv in t println(kv) end
for kv in t2 println(kv) end


kv, st = iterate(t2);
kv, st = iterate(t2, st);
kv, st = iterate(t, st);



#t = Tries.Trie{String, Int}()
#t2 = PureFun.setindex(t, "hello", 33);
#t3 = PureFun.setindex(t2, "world", 42);

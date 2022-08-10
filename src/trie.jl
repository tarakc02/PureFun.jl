# tries {{{
module Tries

using PureFun

# set up {{{
const List = PureFun.Linked.List

Option{T} = Union{Some{T}, Nothing} where T

struct Trie{K,V,K0} <: PureFun.PFDict{K,V} where K0
    v::Option{V}
    m::PureFun.RedBlack.RBDict{Base.Order.ForwardOrdering,K0,Trie{K,V,K0}}
end
# }}}

EdgeMapType(K,V) = PureFun.RedBlack.RBDict{Base.Order.ForwardOrdering,eltype(K),Trie{K,V,eltype(K)}}

# Trie keys should be iterators over some simple key type,
# use `simpletype` to get the inner key type from the outer type
# e.g. String -> Char, PFList{T} -> T
simpletype(t::Trie{K,V}) where {K,V} = eltype(K)

function Trie{K,V}() where {K,V}
    k = eltype(K)
    edgemap = EdgeMapType(K,V)()
    Trie{K,V,k}(nothing, edgemap)
end

edgemap(t::Trie{K,V}) where {K,V} = t.m

Base.isempty(t::Trie) = isnothing(t.v) && isempty(edgemap(t))
Base.empty(t::Trie) = Trie(nothing, empty(edgemap(t)))
Base.IteratorSize(::Trie) = Base.SizeUnknown()

function Base.get(t::Trie, keys, default)
    isempty(keys) && return default
    for k in keys
        isempty(t) && return default
        t = get(edgemap(t), k, empty(t))::typeof(t)
    end
    isnothing(t.v) ? default : something(t.v)
end

function PureFun.setindex(trie::Trie{K}, x, keys) where K
    isempty(keys) && return Trie(Some(x), trie.m)
    k,ks... = keys
    t = get(trie.m, k, empty(trie))
    tprime = setindex(t, x, K(ks))
    Trie(trie.v, setindex(trie.m, tprime, k));
end

PureFun.push(t::Trie, p::Pair) = setindex(t, p[2], p[1])

function Trie(iter)
    peek = first(iter)
    peek isa Pair || return MethodError(Trie, iter)
    K, V = typeof(peek[1]), typeof(peek[2])
    reduce(push, iter, init=Trie{K,V}())
end

function Base.iterate(t::Trie)
    K = keytype(t)
    buffer = List{simpletype(t)}()
    edgestates = List{Any}()
    edgestates = isnothing(t.v) ? edgestates : cons((edgemap(t), ()), edgestates)
    while isnothing(t.v)
        edgeiter = iterate(edgemap(t))
        isnothing(edgeiter) && return nothing
        e, st = edgeiter
        edgestates = cons((edgemap(t), st), edgestates)
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
# }}}

using PureFun
using .Tries: Trie

using Random
ks = [randstring("abcdefghijklmn", rand(6:11)) for _ in 1:10000]
vs = [rand(Int) for _ in 1:10000]

using BenchmarkTools


t = Trie(k => v for (k,v) in zip(ks, vs));
rb = PureFun.RedBlack.RBDict(k => v for (k,v) in zip(ks, vs))
d = Dict(k => v for (k,v) in zip(ks, vs))

@benchmark t = Trie(k => v for (k,v) in zip($ks, $vs))
@benchmark d = Dict(k => v for (k,v) in zip($ks, $vs))
@benchmark rb = PureFun.RedBlack.RBDict(k => v for (k,v) in zip($ks, $vs))

k = rand(ks)
@assert t[k] == d[k]
@btime $rb[$k]
@btime $d[$k]
@btime $t[$k]
@btime get($t, $k, 0)
@btime get($rb, $k, 0)

@code_warntype get(t, k, 0)

for kv in t println(kv) end
for kv in rb println(kv) end


kv, st = iterate(t2);
kv, st = iterate(t2, st);
kv, st = iterate(t, st);



#t = Tries.Trie{String, Int}()
#t2 = PureFun.setindex(t, "hello", 33);
#t3 = PureFun.setindex(t2, "world", 42);

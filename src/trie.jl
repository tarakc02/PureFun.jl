# tries {{{
module Tries

using PureFun
using PureFun.AssocList, PureFun.Chunky, PureFun.Linked

Option{T} = Union{Some{T}, Nothing} where T

#Map{K,V} = PureFun.RedBlack.RBDict{Base.Order.ForwardOrdering,K,V}
Map{K,V} = AssocList.Map{ PureFun.Linked.List{Pair{K,V}}, K, V} where {K,V}

#Map{K,V} = AssocList.Map{ Chunky.List{ Linked.List{ Chunky.Chunk{8, Pair{K,V}} },
#                                       Pair{K,V} }, K, V } where {K,V}

#=

keytype for the edgemaps is eltype(KEY) for the main dict key, which we'll
settle in separate wrappers that implement dict/set intefaces

=#
struct Trie{K,V} <: PureFun.PFDict{K,V}
    v::Option{V}
    edges::Map{K, Trie{K,V}}
end

empty_edgemap(K, V) = AssocList.Map{K,Trie{K,V}}(PureFun.Linked.List)
vtype(::Trie{V}) where V = V

function Trie{K,V}() where {K,V}
    e = empty_edgemap(K,V)
    Trie{K,V}(nothing, e)
end

edges(t::Trie) = t.edges
Base.isempty(t::Trie) = isnothing(t.v) && isempty(edges(t))
function Base.empty(t::Trie{K,V}) where {K,V}
    em = empty(edges(t))
    Trie{K,V}(nothing, em)
end

Base.IteratorSize(::Trie) = Base.SizeUnknown()

function Base.get(t::Trie, keys, default)
    isempty(keys) && return default
    for k in keys
        isempty(t) && return default
        t = get(edges(t), k, empty(t))
    end
    isnothing(t.v) ? default : something(t.v)
end

function PureFun.setindex(trie::Trie{K,V}, x, keys) where {K,V}
    isempty(keys) && return Trie(Some(x), edges(trie))
    k,ks... = keys
    t = get(edges(trie), k, empty(trie))
    tprime = setindex(t, x, ks)
    Trie{K,V}(trie.v, setindex(edges(trie), tprime, k))
end

PureFun.push(t::Trie, p::Pair) = setindex(t, p[2], p[1])

function Trie(iter)
    peek = first(iter)
    peek isa Pair || return MethodError(Trie, iter)
    K, V = eltype(peek[1]), typeof(peek[2])
    reduce(push, iter, init=Trie{K,V}())
end

function Base.iterate(t::Trie{K,V}) where {K,V}
    buffer = Linked.List{K}()
    edgestates = Linked.List{Any}()
    edgestates = isnothing(t.v) ? edgestates : cons((edges(t), ()), edgestates)
    while isnothing(t.v)
        edgeiter = iterate(edges(t))
        isnothing(edgeiter) && return nothing
        e, st = edgeiter
        edgestates = cons((edges(t), st), edgestates)
        buffer = cons(e[1], buffer)
        t = e[2]
    end
    kv = reverse!(collect(buffer)) => something(t.v)
    kv, (edgestates, buffer)
end

function Base.iterate(t::Trie{K,V}, state) where {K,V}
    #K = keytype(t)
    edgestates, buffer = state
    isempty(edgestates) && return nothing

    es, edgestate = head(edgestates)
    edgeiter = edgestate === () ? iterate(es) : iterate(es, edgestate)

    # if the current edgemap is exhausted, go up a level and advance an edge
    while isnothing(edgeiter)
        edgestates = tail(edgestates)
        isempty(edgestates) && return nothing
        buffer = tail(buffer)
        es, edgestate = head(edgestates)
        edgeiter = edgestate === () ? iterate(es) : iterate(es, edgestate)
    end

    edge, edgestate = edgeiter
    trie = edge[2]
    edgestates = cons((es, edgestate), tail(edgestates))
    buffer = cons(edge[1], isempty(buffer) ? buffer : tail(buffer))

    # now descend to the first valid key
    while isnothing(trie.v)
        edgeiter = iterate(edges(trie))
        isnothing(edgeiter) && return nothing
        edge, edgestate = edgeiter
        edgestates = cons((edges(trie), edgestate), edgestates)
        buffer = cons(edge[1], buffer)
        trie = edge[2]
    end
    kv = reverse!(collect(buffer)) => something(trie.v)
    kv, (edgestates, buffer)
end

end
# }}}

using PureFun
using .Tries: Trie

using Random
ks = [randstring("abcdefghijklmn", rand(15:25)) for _ in 1:500]
vs = [rand(Int) for _ in 1:500]

using BenchmarkTools

PureFun.Tries.@Trie MyTrie PureFun.AList.mapof(PureFun.Linked.List)

t = MyTrie(k => v for (k,v) in zip(ks, vs))
rb = PureFun.RedBlack.RBDict(k => v for (k,v) in zip(ks, vs))
d = Dict(k => v for (k,v) in zip(ks, vs))

@benchmark $t[k] setup=k=rand(ks)
@benchmark $rb[k] setup=k=rand(ks)
@benchmark $d[k] setup=k=rand(ks)
@benchmark get($t, k, 0) setup=k=randstring("abcdefghijklmn", rand(7:10))
@benchmark get($rb, k, 0) setup=k=randstring("abcdefghijklmn", rand(7:10))
@benchmark get($d, k, 0) setup=k=randstring("abcdefghijklmn", rand(7:10))
#@btime $d[k] setup=k=rand(ks)

@benchmark setindex($t, 0, k) setup=k=rand(ks)
@benchmark setindex($rb, 0, k) setup=k=rand(ks)

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

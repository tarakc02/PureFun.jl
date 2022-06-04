module Tries # {{{

# imports {{{
using PureFun
using PureFun: PFDict, setindex
using PureFun.RedBlack: RBDict
const List = PureFun.Linked.List
# }}}

# struct defs {{{
Option{T} = Union{Some{T}, Nothing} where T

# `m` is a dict mapping subsequences of K to Tries
struct Trie{M,K,V,P} <: PFDict{K,V} where { M, P<: AbstractVector }
    prefix::P
    v::Option{V}
    m
end
# }}}

function trie_prefixtype(K)
    K === String ? typeof(codeunits("")) : eltype(K)
end

# constructors {{{
function Trie{K,V}(M) where {K,V}
    P = trie_keytype(K)
    edgemap = M{K0,Trie{M}}()
    Trie{M,K,V,K0}(Vector{K0}(), nothing, edgemap)
end

function Trie{M,K,V}(prefix,v,m) where {M,K,V} 
    K0 = eltype(K)
    Trie{M,K,V,K0}(collect(prefix), v, m)
end

# }}}

# getters {{{
edgemap(t::Trie{M,K,V,K0}) where {M,K,V,K0} = t.m::M{K0, Trie{M}}
prefix(t::Trie) = t.prefix
value(t::Trie) = t.v
# }}}

# base interfaces {{{
Base.isempty(t::Trie) = isnothing(t.v) && isempty(edgemap(t))
Base.empty(t::Trie{M,K,V,K0}) where {M,K,V,K0} = Trie{M,K,V,K0}(K0[], nothing, empty(edgemap(t)))
Base.IteratorSize(::Trie) = Base.SizeUnknown()
# }}}

# utils {{{
empty_edgemap(t) = empty(edgemap(t))

function split_node(t::Trie{M,K,V}, newkey, i, x) where {M,K,V}
    # split the node into [1:i-1], [i:end]
    pfix = prefix(t)
    p = pfix[i]
    k = newkey[i]
    old_node = Trie{M,K,V}(pfix[i:end], t.v, edgemap(t))
    new_node = Trie{M,K,V}(newkey[i:end], Some(x), empty_edgemap(t))
    new_edgemap = setindex(empty_edgemap(t), p, old_node)
    new_edgemap = setindex(new_edgemap,      k, new_node)
    # relying on the fact that pfix[1:0] == []
    Trie{M,K,V}(pfix[1:i-1], nothing, new_edgemap)
end
# }}}

# main get/set fns {{{
function Base.get(t::Trie, query, default)
    pfix = prefix(t)
    for (q, p) in zip(query,pfix) 
        q == p || return default
    end
    lp = length(pfix)
    lq = length(query)
    if lp == lq
        isnothing(t.v) && return default
        return something(t.v)
    end
    k = length(pfix)+1
    nxt = get(edgemap(t), query[k], empty(t))::typeof(t)
    isempty(nxt) && return default
    get(nxt, query[k:end], default)
end

function PureFun.setindex(t::Trie{M,K,V}, key, x) where {M,K,V}
    isempty(t) && return Trie{M,K,V}(key, Some(x), empty_edgemap(t))
    pfix = prefix(t)
    if isempty(pfix)
        old_node = get(edgemap(t), key[1], empty(t))
        new_node = setindex(old_node, key, x)
        new_edgemap = setindex(edgemap(t), key[1], new_node)
        return Trie{M,K,V}(pfix, t.v, new_edgemap)
    end
    for (i, (k, p)) in enumerate( zip(key, pfix) )
        k != p && return split_node(t, key, i, x)
    end
    length(key) == length(pfix) && return Trie{M,K,V}(pfix, Some(x), edgemap(t))
    if length(key) > length(pfix)
        i = length(pfix)+1
        old_node = get(edgemap(t), key[i], empty(t))
        new_node = setindex(old_node, key[i:end], x)
        new_edgemap = setindex(edgemap(t), key[i], new_node)
        return Trie{M,K,V}(pfix, t.v, new_edgemap)
    end
    # key is a proper prefix of `t.prefix`
    new_pfix = pfix[length(key)+1:end]
    new_node = Trie{M,K,V}(new_pfix, t.v, edgemap(t))
    new_edgemap = setindex(empty_edgemap(t), new_pfix[1], new_node)
    Trie{M,K,V}(key, Some(x), new_edgemap)
end
# }}}

# build from iter {{{
PureFun.insert(t::Trie, p::Pair) = PureFun.setindex(t, p[1], p[2])

function Trie{M}(iter) where M
    peek = first(iter)
    peek isa Pair || return MethodError(Trie, iter)
    K, V = typeof(peek[1]), typeof(peek[2])
    reduce(insert, iter, init=Trie{K,V}(M))
end

function Trie(iter)
    peek = first(iter)
    peek isa Pair || return MethodError(Trie, iter)
    K, V = typeof(peek[1]), typeof(peek[2])
    reduce(insert, iter, init=Trie{K,V}(PureFun.RedBlack.RBDict{Base.Order.ForwardOrdering}))
end
# }}}

# iteration {{{
simpletype(t::Trie{M,K,V,K0}) where {M,K,V,K0} = K0
function Base.iterate(t::Trie)
    K = keytype(t)
    K0 = eltype(K)
    buffer = Vector{Vector{K0}}()
    edgestates = List{Any}()
    edgestates = isnothing(t.v) ? edgestates : cons((edgemap(t), ()), edgestates) 
    while isnothing(t.v)
        edgeiter = iterate(edgemap(t))
        isnothing(edgeiter) && return nothing
        e, st = edgeiter
        edgestates = cons((edgemap(t), st), edgestates)
        t = e[2]
        push!(buffer, prefix(t))
    end
    key =  collect(Iterators.flatten(buffer))
    kv = K(key) => something(t.v)
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
        pop!(buffer)
        edges, edgestate = head(edgestates)
        edgeiter = edgestate === () ? iterate(edges) : iterate(edges, edgestate)
    end

    edge, edgestate = edgeiter
    trie = edge[2]
    edgestates = cons((edges, edgestate), tail(edgestates))
    !isempty(buffer) && pop!(buffer)
    push!(buffer, prefix(trie))
    #buffer = cons(edge[1], isempty(buffer) ? buffer : tail(buffer))

    # now descend to the first valid key
    while isnothing(trie.v)
        edgeiter = iterate(trie.m)
        isnothing(edgeiter) && return nothing
        edge, edgestate = edgeiter
        edgestates = cons((trie.m, edgestate), edgestates)
        trie = edge[2]
        buffer = push!(buffer, prefix(trie))
    end
    key =  collect(Iterators.flatten(buffer))
    kv = K(key) => something(trie.v)
    kv, (edgestates, buffer)
end

# }}}

end # }}}

using PureFun
using .Tries: Trie

using Random
#ks = ["repeatedrepeatedrepeatedrepeated"*randstring("abcdefg", rand(5:10)) for _ in 1:100]
#vs = [rand(Int) for _ in 1:100]
ks = [randstring("abcdefg", rand(3:5)) for _ in 1:1000] |> unique
vs = [rand(Int) for _ in eachindex(ks)]

t = Trie(k => v for (k,v) in zip(ks, vs));
rb = PureFun.RedBlack.RBDict(k => v for (k,v) in zip(ks, vs));
d = Dict(k => v for (k,v) in zip(ks, vs));

function lookup_vec(x, keys, values)
    for (k,v) in zip(keys, values)
        k == x && return v
    end
    throw(KeyError(x))
end

@btime $rb[k] setup=k=rand(ks)
@btime lookup_vec(k, $ks, $vs) setup=k=rand(ks)


rb = PureFun.RedBlack.RBDict(c => c for c in 'A':'z');
vec = collect('A':'z')

@btime $rb[c] setup=c=rand('A':'z')
@btime findfirst($vec .== c) setup=c=rand('A':'z')
@btime for v in $vec v == c || return true end setup=c=rand('A':'z')

k = rand(ks)
@assert t[k] == d[k]

using BenchmarkTools
@btime get($t, k, -1) setup=k=randstring("xyz", 10)
@btime get($d, k, -1) setup=k=randstring("xyz", 10)
@btime $t[$k]
@btime $rb[$k]
@btime $d[$k]
@btime get($t, $k, 0)
@btime get($rb, $k, 0)

@code_warntype get(t, k, 0)




chars = rand(Char, 10)
strings = [randstring("abcdefg", 10) for _ in 1:10]

rbchar = PureFun.RedBlack.RBDict(c => c for c in chars)
rbstrg = PureFun.RedBlack.RBDict(s => s for s in strings)

# hits
@benchmark $rbchar[c] setup=c=rand(chars)
@benchmark ($rbchar[c1] > $rbchar[c2]) setup=(c1=rand(chars); c2=rand(chars))
@benchmark $rbstrg[s] setup=s=rand(strings)

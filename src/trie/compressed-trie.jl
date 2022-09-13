module Tries # {{{
using PureFun

# helpers {{{
function first_nonmatch(itr1, itr2)
    for (i, (e1, e2)) in enumerate(zip(itr1, itr2))
        e1 == e2 || return i
    end
    next_index(itr1, itr2)
end
next_index(itr1, itr2) = 1 + min(lastindex(itr1), lastindex(itr2))
#}}}

# basics {{{
Map{K,V} = PureFun.AssocList.Map{ PureFun.Linked.List{Pair{K,V}},
                                 K, V} where {K,V}

#Map{K,V} = PureFun.RedBlack.RBDict{Base.Order.ForwardOrdering,K,V}

Option{T} = Union{Some{T}, Nothing} where T

struct Trie{K,K0,V} <: PureFun.PFDict{K,V}
    kv::Option{Pair{K,V}}
    i::Int
    edges::Map{K0, Trie{K,K0,V}}
end

isvalid(t::Trie) = t.kv !== nothing
edges(t::Trie) = t.edges
Base.isempty(t::Trie) = !isvalid(t) && isempty(edges(t))
ind(t::Trie) = t.i

_ktype(t::Trie{K,K0,V}) where {K,K0,V} = K
_k0type(t::Trie{K,K0,V}) where {K,K0,V} = K0
_vtype(t::Trie{K,K0,V}) where {K,K0,V} = V
# }}}

# empty constructors {{{
empty_edgemap(K,K0,V) = PureFun.AssocList.Map{K0, Trie{K,K0,V}}()
#empty_edgemap(K,K0,V) = PureFun.RedBlack.RBDict{K0, Trie{K,K0,V}}()

function Trie{K,K0,V}() where {K,K0,V}
    Trie{K, K0, V}(nothing, 1, empty_edgemap(K,K0,V))
end

Trie{K,V}() where {K,V} = Trie{K,eltype(K),V}()

function Base.empty(t::Trie)
    Trie{_ktype(t), _k0type(t), _vtype(t)}()
end
# }}}

# lookup/update {{{
struct SearchFail end

keymatch(trie::Trie, key) = keymatch(trie.kv, key)
keymatch(::Nothing, key) = false
keymatch(kv, key) = key == something(kv).first

function Base.get(trie::Trie, key, default)
    i = ind(trie)
    i == (1 + lastindex(key)) &&
        keymatch(trie, key) &&
        return something(trie.kv).second
    i > lastindex(key) && return default
    t = get(edges(trie), key[i], SearchFail())
    t isa SearchFail ? default : get(t, key, default)
end

function _first_valid_child(trie)
    isvalid(trie) ? trie : _first_valid_child( first(edges(trie)).second )
end

function _next_key(trie)
    t = _first_valid_child(trie)
    something(t.kv).first
end

function _get_split_ind(trie, key)
    k2 = _next_key(trie)
    i = first_nonmatch(k2, key)
    i, lastindex(k2) >= i ? k2[i] : k2[firstindex(k2)]
end

function _split(trie, key)
    i = ind(trie)
    i > lastindex(key) && return _get_split_ind(trie, key)
    t = get(edges(trie), key[i], SearchFail())
    t isa SearchFail && return _get_split_ind(trie, key)
    _split(t, key)
end


function initval(trie, key, value)
    newnode = singleton(trie, key, value)
    i = firstindex(key)
    Trie(trie.kv, i, setindex(edges(trie), newnode, key[i]))
end

function Base.setindex(trie, value, key)
    isempty(trie) && return initval(trie, key, value)
    i, ch = _split(trie, key)
    _setind(trie, i, key, value, ch)
end

function singleton(trie, key, value)
    Trie(Some(Pair(key, value)),
         1+lastindex(key),
         empty(edges(trie)))
end

function _setind(trie, i, key, value, ch)
    j = ind(trie)
    if j < i
        e = edges(trie)
        # we know this exists
        nxt = e[key[j]]
        nu = _setind(nxt, i, key, value, ch)
        return Trie(trie.kv, j, setindex(e, nu, key[j]))
    elseif j > i
        e = empty(edges(trie))
        nu = singleton(trie, key, value)
        nu_edge = setindex(e, trie, ch)
        return Trie{_ktype(trie), _k0type(trie), _vtype(trie)}(nothing, i, setindex(nu_edge, nu, key[i]))
    elseif isvalid(trie) && lastindex(something(trie.kv).first) == lastindex(key)
        return Trie(Some(Pair(key, value)), j, edges(trie))
    else
        nu = singleton(trie, key, value)
        return Trie(trie.kv, j, setindex(edges(trie), nu, key[j]))
    end

end

# }}}

# iteration {{{

_edgelist(t) = PureFun.Linked.List(collect(values(edges(t))))

function Base.iterate(t::Trie)
    isvalid(t) ?
        (something(t.kv), _edgelist(t)) :
        iterate(t, _edgelist(t))
end

function Base.iterate(trie::Trie, state)
    isempty(state) && return nothing
    t = head(state)
    newstate = _edgelist(t) ⧺ tail(state)
    isvalid(t) ?
        (something(t.kv), newstate) :
        iterate(t, newstate)
end

# }}}

# etc {{{

PureFun.push(t::Trie, p::Pair) = setindex(t, p[2], p[1])

function Trie(iter)
    peek = first(iter)
    peek isa Pair || return MethodError(Trie, iter)
    K, V = typeof(peek[1]), typeof(peek[2])
    reduce(push, iter, init=Trie{K,V}())
end

# }}}

end

# }}}

using PureFun
using .Tries: Trie

t = Trie{String,Int}()
tests = ["tarak" => 1, "taraxxx" => 2, "taraks" => 3, "tarak" => 4]
test = accumulate(push, tests, init = t)

# failing
setindex(t, -999, "")

using Random
#ks = [randstring("abcdefghijklmn", rand(15:25)) for _ in 1:500]
ks = [randstring(rand(5:15)) for _ in 1:500]
vs = [rand(Int) for _ in 1:500]

using BenchmarkTools

@btime Trie(k => v for (k,v) in zip(ks, vs))
@btime PureFun.RedBlack.RBDict(k => v for (k,v) in zip(ks, vs))
@btime Dict(k => v for (k,v) in zip(ks, vs))

trie = Trie(k => v for (k,v) in zip(ks, vs))
@assert all(haskey(trie, k) for k in ks)
rb = PureFun.RedBlack.RBDict(k => v for (k,v) in zip(ks, vs))
d = Dict(k => v for (k,v) in zip(ks, vs))

@btime all($trie[k] == $vs[i] for (i,k) in enumerate($ks))
@btime all($d[k]    == $vs[i] for (i,k) in enumerate($ks))
@btime all($rb[k]   == $vs[i] for (i,k) in enumerate($ks))

@btime $trie[k] setup = k = rand(ks)
@btime get($trie, k, -1) setup = k = randstring(rand(5:15))
@btime $rb[k] setup = k = rand(ks)
@btime get($rb, k, -1) setup = k = randstring(rand(5:15))
@btime $d[k] setup = k = rand(ks)
@btime get($d, k, -1) setup = k = randstring(rand(5:15))

Base.summarysize(trie) / Base.summarysize(d)
Base.summarysize(rb) / Base.summarysize(d)

@btime setindex($trie, value, key) setup=(key = randstring(5); value = rand(Int))
@btime setindex($rb, value, key) setup=(key = randstring(5); value = rand(Int))

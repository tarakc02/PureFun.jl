module Tries
using ..PureFun

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
Option{T} = Union{Some{T}, Nothing} where T

abstract type Trie{K,V} <: PureFun.PFDict{K,V} end

_isvalid(t::Trie) = t.kv !== nothing
subtries(t::Trie) = t.subtries
Base.isempty(t::Trie) = !_isvalid(t) && isempty(subtries(t))
ind(t::Trie) = t.i
# }}}

triekey(k) = k
triekey(k::String) = codeunits(k)

function iterable_key end

_itereltype(::typeof(triekey), ::Type{String}) = codeunit("")
_itereltype(::typeof(triekey), ::Type{T}) where T = eltype(T)

# trie types {{{
macro Trie(Name,DictType,keyfunc=triekey)
    :(
      struct $Name{K,K0,V} <: Trie{K,V}
         kv::Option{Pair{K,V}}
         i::Int
         subtries::$(esc(DictType)){K0, $Name{K,K0,V}}
         function $Name{K,V}() where {K,V}
             K0 = _itereltype($(esc(keyfunc)), K)
             st = $(esc(DictType)){K0, $Name{K, K0, V}}()
             new{K,K0,V}(nothing, 1, st)
         end
         function $Name{K,K0,V}() where {K,K0,V}
             st = $(esc(DictType)){K0, $Name{K, K0, V}}()
             new{K,K0,V}(nothing, 1, st)
         end
         $Name{K,K0,V}(p, ix, e) where {K,K0,V} = new{K,K0,V}(p, ix, e)
         function $Name(iter)
             isempty(iter) && return $Name{Any,Any}()
             peek = first(iter)
             peek isa Pair || throw(MethodError($Name, iter))
             K, V = typeof(peek[1]), typeof(peek[2])
             reduce(push, iter, init=$Name{K,V}())
         end
     end;
     PureFun.Tries.iterable_key(::$(esc(Name)), k) = $(esc(keyfunc))(k)
    )
end
# }}}

# empty constructors {{{
function Base.empty(t::Trie)
    typeof(t)()
end
# }}}

# accessors {{{

_kv(trie)    = trie.kv
#_key(trie)   = something(trie.kv).first
_key(trie)   = iterable_key(trie, something(trie.kv).first)
#_value(trie) = something(trie.kv).second

# }}}

# lookup/update {{{
struct SearchFail end

function Base.get(trie::Trie, key, default)
    ikey = iterable_key(trie, key)
    maybekv = _get(trie, ikey)
    maybekv === nothing && return default
    kv = something(maybekv)
    k = kv.first
    k == key ? kv.second : default
end

function _get(trie::Trie, key)::Option{eltype(trie)}
    i = ind(trie)
    i == (1 + lastindex(key)) && return _kv(trie)
    i > lastindex(key) && return nothing
    t = get(subtries(trie), key[i], SearchFail())
    t isa SearchFail ? nothing : _get(t, key)
end

function _first_valid_child(trie)
    _isvalid(trie) ? trie : _first_valid_child( first(values(subtries(trie))) )
end

function _next_key(trie)
    t = _first_valid_child(trie)
    _key(t)
end

function _get_split_ind(trie, key)
    k2 = _next_key(trie)
    i = first_nonmatch(k2, key)
    i, lastindex(k2) >= i ? k2[i] : k2[firstindex(k2)]
end

function _split(trie, key)
    i = ind(trie)
    i > lastindex(key) && return _get_split_ind(trie, key)
    t = get(subtries(trie), key[i], SearchFail())
    t isa SearchFail && return _get_split_ind(trie, key)
    _split(t, key)
end

function singleton(trie, key, kv)
    typeof(trie)(kv,
                 1+lastindex(key),
                 empty(subtries(trie)))
end

function initval(trie, key, kv)
    newnode = singleton(trie, key, kv)
    i = firstindex(key)
    typeof(trie)(_kv(trie), i, setindex(subtries(trie), newnode, key[i]))
end

function Base.setindex(trie::Trie, value, k)
    kv = Some(Pair(k, value))
    key = iterable_key(trie, k)
    isempty(trie) && return initval(trie, key, kv)
    i, ch = _split(trie, key)
    _setind(trie, i, key, kv, ch)
end

function _setind(trie, i, key, kv, ch)
    j = ind(trie)
    if j < i
        st = subtries(trie)
        # we know this exists
        nxt = st[key[j]]
        nu = _setind(nxt, i, key, kv, ch)
        return typeof(trie)(_kv(trie), j, setindex(st, nu, key[j]))
    elseif j > i
        st = empty(subtries(trie))
        nu = singleton(trie, key, kv)
        nu_st = setindex(st, trie, ch)
        return typeof(trie)(nothing, i, setindex(nu_st, nu, key[i]))
    elseif _isvalid(trie) && lastindex(_key(trie)) == lastindex(key)
        return typeof(trie)(kv, j, subtries(trie))
    else
        nu = singleton(trie, key, kv)
        return typeof(trie)(_kv(trie), j, setindex(subtries(trie), nu, key[j]))
    end
end

# }}}

# iteration {{{

_edgelist(t) = PureFun.Linked.List(collect(values(subtries(t))))
#_edgelist(t) = reverse(foldl(pushfirst, values(subtries(t)), init = PureFun.Linked.List{valtype(t)}()))

function Base.iterate(t::Trie)
    _isvalid(t) ?
        (something(_kv(t)), _edgelist(t)) :
        iterate(t, _edgelist(t))
end

function Base.iterate(trie::Trie, state)
    isempty(state) && return nothing
    t = head(state)
    newstate = _edgelist(t) ⧺ tail(state)
    _isvalid(t) ?
        (something(_kv(t)), newstate) :
        iterate(t, newstate)
end

Base.IteratorSize(t::Trie) = Base.SizeUnknown()

# }}}

# etc {{{

PureFun.push(t::Trie, p::Pair) = setindex(t, p[2], p[1])

# }}}

end


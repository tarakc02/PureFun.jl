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
_itereltype(f, ::Type{T}) where T = eltype(Core.Compiler.return_type(f, Tuple{T}))

# trie types {{{

@doc raw"""
    Trie.@trie Name edgemap
    Trie.@trie Name edgemap keyfunc

Tries are defined by an optional `keyfunc`, which takes keys and returns an
iterator of simpler keys, and the `edgemap`, which maps the simpler keys to
subtries. if `keyfunc`  is not specified it will be set to the identity
function for all types except for Strings, for which it is `codeunits` (in
order to properly handle variable width character encodings). Once `Name` has
been defined, it can be used like any other [`PureFun.PFDict`](@ref)

# Examples

```jldoctest
julia> using PureFun.Tries
julia> Tries.@trie SimpleMap PureFun.Association.List

julia> s = SimpleMap{String,Int}()
SimpleMap{String, Int64}()

julia> setindex(s, 42, "hello world")
SimpleMap{String, Int64}(...):
  "hello world" => 42

julia> SimpleMap(c => c for c in 'a':'e')
SimpleMap{Char, Char}(...):
  'e' => 'e'
  'd' => 'd'
  'c' => 'c'
  'b' => 'b'
  'a' => 'a'
```

The `edgemap` can be any data structure which implements the PFDict interface:
it iterates pairs, has `get`, `setindex`, and `isempty` methods, and an empty
constructor that has the signature `edgemap{K,V}()`. A tricky detail is that
`edgemap{K,V}` should be a concrete type for concrete `K` and `V`, something
you have to account for when defining the trie type if your edgemap dictionary
type has extra type parameters. For example, here we must specify the ordering
parameter for our RedBlack dictionary in order to use it as the `edgemap`:

```jldoctest
julia> Tries.@trie RedBlackMap PureFun.RedBlack.RBDict{Base.Order.ForwardOrdering}

julia> RedBlackMap(("hello" => "world", "reject" => "fascism"))
RedBlackMap{String, String}(...):
  "hello"  => "world"
  "reject" => "fascism"
```

## Cache-efficient bitmap tries

[`PureFun.Contiguous.biterate`](@ref) breaks single integer keys into iterators
of smaller integer keys. [`PureFun.Contiguous.bitmap`](@ref) is a fast
dictionary for small integer keys. By combining them, we end up with a
[bitmap-trie](https://en.wikipedia.org/wiki/Bitwise_trie_with_bitmap)

```jldoctest
julia> PureFun.Tries.@trie BitMapTrie PureFun.Contiguous.bitmap(16) PureFun.Contiguous.biterate(4)

julia> BitMapTrie(x => Char(x) for x in rand(UInt16, 5))
BitMapTrie{UInt16, Char}(...):
  0x5f60 => '彠'
  0xce8b => '캋'
  0x92c6 => '鋆'
  0xa2ce => 'ꋎ'
  0xadff => '귿'

julia> PureFun.Tries.@trie BitMapTrie64 PureFun.Contiguous.bitmap(64) PureFun.Contiguous.biterate(6)

julia> b = BitMapTrie64(x => 2x for x in 1:1_000)
BitMapTrie64{Int64, Int64}(...):
  64  => 128
  128 => 256
  192 => 384
  256 => 512
  320 => 640
  384 => 768
  448 => 896
  512 => 1024
  576 => 1152
  640 => 1280
  ⋮   => ⋮

julia> b[13]
26
```

Tries themselves can be edgemaps for other tries:

```jldoctest
julia> @trie BitMapTrie PureFun.Contiguous.bitmap(16) PureFun.Contiguous.biterate(4)
julia> PureFun.Tries.@trie StringTrie Main.BitMapTrie codeunits

julia> StringTrie(("hello" => 1, "world" => 2))
StringTrie{String, Int64}(...):
  "world" => 2
  "hello" => 1
```
"""
macro trie(Name, edgemap, keyfunc=triekey)
    :(
      struct $Name{K,V} <: Trie{K,V}
         kv::Option{Pair{K,V}}
         i::Int
         _subtries
         function $Name{K,V}() where {K,V}
             K0 = _itereltype($(esc(keyfunc)), K)
             st = $(esc(edgemap)){K0, $Name{K, V}}()
             new{K,V}(nothing, 1, st)
         end
         $Name{K,V}(p, ix, e) where {K,V} = new{K,V}(p, ix, e)
         function $Name(iter)
             isempty(iter) && return $Name{Any,Any}()
             peek = first(iter)
             peek isa Pair || throw(MethodError($Name, iter))
             K, V = typeof(peek[1]), typeof(peek[2])
             reduce(push, iter, init=$Name{K,V}())
         end
     end;
     PureFun.Tries.iterable_key(::$(esc(Name)), k) = $(esc(keyfunc))(k);
     function PureFun.Tries.subtries(obj::$(esc(Name)){K,V}) where {K,V}
         K0 = _itereltype($(esc(keyfunc)), K)
         return obj._subtries::$edgemap{K0, $(esc(Name)){K,V}}
     end
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

#function PureFun.update_at(f::Function, t::Trie, k, default)
#    func(x) = Some(Pair(k, f(x)))
#    func() = func(default)
#    isempty(trie) && return initval(t, iterable_key(k), func())
#    i, ch = _split(trie, key)
#    _update_at(trie, i, key, func, ch)
#end
#
#function _update_at(trie, i, key, func, ch)
#    j = ind(trie)
#    if j < i
#        st = subtries(trie)
#        # we know this exists
#        nxt = st[key[j]]
#        nu = _update_at(nxt, i, key, func, ch)
#        return typeof(trie)(_kv(trie), j, setindex(st, nu, key[j]))
#    elseif j > i
#        st = empty(subtries(trie))
#        nu = singleton(trie, key, func())
#        nu_st = setindex(st, trie, ch)
#        return typeof(trie)(nothing, i, setindex(nu_st, nu, key[i]))
#    elseif _isvalid(trie) && lastindex(_key(trie)) == lastindex(key)
#        return typeof(trie)(#kv -- should be func()#, j, subtries(trie))
#    else
#        nu = singleton(trie, key, kv)
#        return typeof(trie)(_kv(trie), j, setindex(subtries(trie), nu, key[j]))
#    end
#end


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


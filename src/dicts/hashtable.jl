module HashMaps

export @hashmap

using ..PureFun

abstract type HashMap{K,V} <: PureFun.PFDict{K,V} end

function approxmap end
function hasher end

_return_type(f, ::Type{T}) where T = Core.Compiler.return_type(f, Tuple{T})
approx_get(d::HashMap, key, default) = get(approxmap(d), key, default)

@doc raw"""
    HashMaps.@hashmap(Name, approx = ..., exact = ...)
    HashMaps.@hashmap(Name, approx = ..., exact = ..., hashfunc = ...)

From exercise 10.11 in $\S{10.3.1}$:

> Another common data structure that involves multiple layers of finite maps is
> the *hash table*. Complete the following implementation . . .
> 
> ```
> functor HashTable(structure Approx : FiniteMap
>                   structure Exact : FiniteMap
>                   val hash : Exact.Key → Approx.Key) : FiniteMap =
> struct
>     type Key = Exact.Key
>     type α Map = α Exact.Map Approx.Map
>     ...
>     fun lookup(k,m) = Exact.lookup(k, Approx.lookup(hash k, m))
> end
> ```
> 
> The advantage of this representation is that `Approx` can use an efficient key
> type (such as integers) and `Exact` can use a trivial implementation (such as
> association lists)

To define a hash map, provide a container type for `approx`, one for `exact`,
and, optionally, a hash function. To avoid confusion, the container type
arguments must be named.

# Examples

The dictionary types for the approx and exact maps can be any type `DictType`
that satisfies the following:

- `DictType{K,V}` describes a concrete type
- `DictType{K,V}()` initializes an empty dictionary for keys of type `K` and
  values of type `V`
- has methods for `get(::DictType, key, default)` and `setindex(::DictType, val, key)`

In the following example, we have to specify the ordering parameter for the
red-black dictionary, so that it conforms to the required specifications. Note
also you might need to fully specify object names including their module (so
e.g. `Main.MyApproxMap` rather than `MyApproxMap`). You can get around this
restriction by defining `const` type aliases, as in this example:

```jldoctest
julia> using PureFun, PureFun.HashMaps

julia> const RB = PureFun.RedBlack.RBDict{Base.Order.ForwardOrdering}
PureFun.RedBlack.RBDict{Base.Order.ForwardOrdering}

julia> const assoclist = PureFun.Association.List
PureFun.Association.List

julia> HashMaps.@hashmap(MyHashMap, approx = RB, exact = assoclist)

julia> setindex(MyHashMap{String,Int}(), 42, "hello world")
MyHashMap{String, Int64}(...):
  "hello world" => 42

julia> MyHashMap(char => Int(char) for char in 'a':'f')
MyHashMap{Char, Int64}(...):
  'c' => 99
  'd' => 100
  'e' => 101
  'f' => 102
  'b' => 98
  'a' => 97
```

With this general framework for hashmaps as nested finite maps, we can
implement the [Hash Array Mapped
Trie](https://www.semanticscholar.org/paper/Ideal-Hash-Trees-Bagwell/4fc240d0d9e690cb9b0bcb2f8a5e5ca918b01410),
which features prominently among [Clojure's standard data
structures](https://clojure.org/reference/data_structures), and in
[FunctionalCollections.jl](https://github.com/JuliaCollections/FunctionalCollections.jl).
We assemble a bitmapped trie to use as our `approx` map, and use an association
list for the `exact` map. For no particular reason except to demonstrate the
functionality, here instead of relying on the usual hash function we specify
our own hash function (in this case, it is just the hash of the hash):

# Examples

```jldoctest
julia> using PureFun, PureFun.Tries, PureFun.HashMaps

julia> PureFun.Tries.@trie(BitMapTrie64,
                           PureFun.Contiguous.bitmap(64),
                           PureFun.Contiguous.biterate(6))

julia> HashMaps.@hashmap(HAMT,
                         approx   = Main.BitMapTrie64,
                         exact    = PureFun.Association.List,
                         hashfunc = hash ∘ hash)

julia> HAMT{String,Int}()
HAMT{String, Int64}()

julia> HAMT(x => Char(x) for x in 97:105)
HAMT{Int64, Char}(...):
  105 => 'i'
  99  => 'c'
  98  => 'b'
  103 => 'g'
  102 => 'f'
  97  => 'a'
  104 => 'h'
  100 => 'd'
  101 => 'e'
```
"""
macro hashmap(Name, kwargs...)
    pieces = Dict(ex.args[1] => ex.args[2] for ex in kwargs if ex.head == :(=))
    exact = pieces[:exact]
    approx = pieces[:approx]
    hashfunc = get(pieces, :hashfunc, Base.hash)
:(
  struct $Name{K,V} <: HashMap{K,V}
      _approx
      function $Name{K,V}() where {K,V}
          Exact = $(esc(exact))
          Approx = $(esc(approx))
          K0 = _return_type($(esc(hashfunc)), K)
          ap = Approx{K0, Exact{K,V}}()
          new{K,V}(ap)
      end
      $Name{K,V}(ap) where {K,V} = new{K,V}(ap);
      function $Name(iter)
          peek = first(iter)
          peek isa Pair || throw(MethodError($Name, iter))
          K, V = typeof(peek[1]), typeof(peek[2])
          reduce(push, iter, init=$Name{K,V}())
      end
  end;
  function HashMaps.approxmap(obj::$(esc(Name)){K,V}) where {K,V}
      Exact = $(esc(exact))
      Approx = $(esc(approx))
      K0 = _return_type($(esc(hashfunc)), K)
      return obj._approx::Approx{K0, Exact{K,V}}
  end;
  HashMaps.hasher(::Type{<:$(esc(Name))}) = $(esc(hashfunc))
)
end

struct SearchFail end
const failure = SearchFail()

function Base.get(m::HashMap, key, default)
    exact = approx_get(m, hasher(typeof(m))(key), failure)
    exact === failure ? default : get(exact, key, default)
end

exactmap(m::HashMap) = valtype(typeof(approxmap(m)))

function Base.setindex(m::HashMap, val, key)
    k = hasher(typeof(m))(key)
    nu = update_at(approxmap(m), k, exactmap(m)()) do bucket
        setindex(bucket, val, key)
    end
    typeof(m)(nu)
end

PureFun.push(m::HashMap, kv) = setindex(m, kv.second, kv.first)

Base.IteratorSize(m::HashMap) = Base.SizeUnknown()

function Base.iterate(m::HashMap)
    it = iterate(approxmap(m))
    it === nothing && return nothing
    kvs = it[1]
    approx_st = it[2]
    kv_it = iterate(kvs.second)
    while kv_it === nothing
        it = iterate(approxmap(m), approx_st)
        it === nothing && return nothing
        kvs = it[1]
        approx_st = it[2]
        kv_it = iterate(kvs.second)
    end
    kv_it[1], (approx_st, kvs, kv_it[2])
end

function Base.iterate(m::HashMap, state)
    approx_st, kvs, kv_st = state
    kv_it = iterate(kvs.second, kv_st)
    while kv_it === nothing
        it = iterate(approxmap(m), approx_st)
        it === nothing && return nothing
        kvs = it[1]
        approx_st = it[2]
        kv_it = iterate(kvs.second)
    end
    kv_it[1], (approx_st, kvs, kv_it[2])
end

Base.isempty(m::HashMap) = isempty(approxmap(m))
Base.empty(m::HashMap) = typeof(m)(empty(approxmap(m)))

end

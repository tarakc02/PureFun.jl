module HashTable

using ..PureFun
using ..PureFun.Contiguous: bitmap, biterate

# the hash map {{{

const docstring = raw"""
    HashTable.HashMap8
    HashTable.HashMap16
    HashTable.HashMap32
    HashTable.HashMap64
    HashTable.HashMap128

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

Hash maps in PureFun.jl uses [`PureFun.Association.List`](@ref) for the `Exact`
map, and a bitmapped [`PureFun.Tries.@trie`](@ref) of hash values for the
`Approx` map. The resulting data structure is nearly identical to the one
described in [Ideal Hash
Trees](https://www.semanticscholar.org/paper/Ideal-Hash-Trees-Bagwell/4fc240d0d9e690cb9b0bcb2f8a5e5ca918b01410),
which also features prominently among [Clojure's standard data
structures](https://clojure.org/reference/data_structures), and in
[FunctionalCollections.jl](https://github.com/JuliaCollections/FunctionalCollections.jl).
`HashMap8` uses a trie with 8-way branching, `HashMap16` has 16-way branching,
and so on.

# Examples

```jldoctest
julia> using PureFun.HashTable: HashMap64

julia> d = HashMap64(("hello" => 1, "world" => 2))
PureFun.HashTable.HashMap{PureFun.HashTable.BitMapTrie64{UInt64, PureFun.Association.List{String, Int64}}, String, Int64}(...):
  "hello" => 1
  "world" => 2

julia> d["world"]
2

julia> setindex(d, 42, "another entry")
PureFun.HashTable.HashMap{PureFun.HashTable.BitMapTrie64{UInt64, PureFun.Association.List{String, Int64}}, String, Int64}(...):
  "another entry" => 42
  "hello"         => 1
  "world"         => 2
```
"""

# tries that convert inputs to iterators over ints, and use bitmaps as the
# edgemaps
PureFun.Tries.@trie BitMapTrie8   PureFun.Contiguous.bitmap(Val{8}())   PureFun.Contiguous.biterate(Val{3}())
PureFun.Tries.@trie BitMapTrie16  PureFun.Contiguous.bitmap(Val{16}())  PureFun.Contiguous.biterate(Val{4}())
PureFun.Tries.@trie BitMapTrie32  PureFun.Contiguous.bitmap(Val{32}())  PureFun.Contiguous.biterate(Val{5}())
PureFun.Tries.@trie BitMapTrie64  PureFun.Contiguous.bitmap(Val{64}())  PureFun.Contiguous.biterate(Val{6}())
PureFun.Tries.@trie BitMapTrie128 PureFun.Contiguous.bitmap(Val{128}()) PureFun.Contiguous.biterate(Val{7}())

BitMapTrie = Union{BitMapTrie8,
                   BitMapTrie16,
                   BitMapTrie32,
                   BitMapTrie64,
                   BitMapTrie128}

@doc docstring
struct HashMap{T,K,V} <: PureFun.PFDict{K,V} where {T <: BitMapTrie}
    trie::T
    function HashMap{T,K,V}() where {K,V,T<:BitMapTrie}
        new{T,K,V}(T())
    end
    HashMap{T,K,V}(trie) where {T,K,V} = new{T,K,V}(trie)
end

Bucket{K,V} = PureFun.Association.List{K, V} where {K,V}

@doc docstring
HashMap8{K,V}   = HashMap{   BitMapTrie8{ UInt, Bucket{K,V} }, K,V } where {K,V}

@doc docstring
HashMap16{K,V}  = HashMap{  BitMapTrie16{ UInt, Bucket{K,V} }, K,V } where {K,V}

@doc docstring
HashMap32{K,V}  = HashMap{  BitMapTrie32{ UInt, Bucket{K,V} }, K,V } where {K,V}

@doc docstring
HashMap64{K,V}  = HashMap{  BitMapTrie64{ UInt, Bucket{K,V} }, K,V } where {K,V}

@doc docstring
HashMap128{K,V} = HashMap{ BitMapTrie128{ UInt, Bucket{K,V} }, K,V } where {K,V}

function _fromiter(iter, HM)
    peek = first(iter)
    peek isa Pair || throw(MethodError(HM, iter))
    K, V = typeof(peek[1]), typeof(peek[2])
    reduce(push, iter, init=HM{K,V}())
end

HashMap8(iter)   = _fromiter(iter, HashMap8)
HashMap16(iter)  = _fromiter(iter, HashMap16)
HashMap32(iter)  = _fromiter(iter, HashMap32)
HashMap64(iter)  = _fromiter(iter, HashMap64)
HashMap128(iter) = _fromiter(iter, HashMap128)

function Base.iterate(m::HashMap)
    it = iterate(m.trie)
    it === nothing && return nothing
    # k is hashedkey, v is a linked list of {k,v}
    kvs = it[1]
    trie_st = it[2]
    kv_it = iterate(kvs.second)
    while kv_it === nothing
        it = iterate(m.trie, trie_st)
        it === nothing && return nothing
        kvs = it[1]
        trie_st = it[2]
        kv_it = iterate(kvs.second)
    end
    kv_it[1], (trie_st, kvs, kv_it[2])
end

function Base.iterate(m::HashMap, state)
    trie_st, kvs, kv_st = state
    kv_it = iterate(kvs.second, kv_st)
    while kv_it === nothing
        it = iterate(m.trie, trie_st)
        it === nothing && return nothing
        kvs = it[1]
        trie_st = it[2]
        kv_it = iterate(kvs.second)
    end
    kv_it[1], (trie_st, kvs, kv_it[2])
end

function Base.get(m::HashMap, key, default)
    k = hash(key)
    bucket = get(m.trie, k, Bucket{keytype(m), valtype(m)}())
    get(bucket, key, default)
end

function Base.setindex(m::HashMap, val, key)
    k = hash(key)
    nu = update_at(m.trie, k, Bucket{keytype(m), valtype(m)}()) do bucket
        setindex(bucket, val, key)
    end
    typeof(m)(nu)
end

PureFun.push(m::HashMap, kv) = setindex(m, kv.second, kv.first)

Base.IteratorSize(m::HashMap) = Base.SizeUnknown()

# }}}

end

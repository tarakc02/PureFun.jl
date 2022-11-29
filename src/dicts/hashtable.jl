module HashTable

using ..PureFun
using ..PureFun.Contiguous: bitmap, biterate

# the hash map {{{

# tries that convert inputs to iterators over ints, and use bitmaps as the
# edgemaps
PureFun.Tries.@Trie BitMapTrie8   PureFun.Contiguous.bitmap(Val{8}())   PureFun.Contiguous.biterate(Val{3}())
PureFun.Tries.@Trie BitMapTrie16  PureFun.Contiguous.bitmap(Val{16}())  PureFun.Contiguous.biterate(Val{4}())
PureFun.Tries.@Trie BitMapTrie32  PureFun.Contiguous.bitmap(Val{32}())  PureFun.Contiguous.biterate(Val{5}())
PureFun.Tries.@Trie BitMapTrie64  PureFun.Contiguous.bitmap(Val{64}())  PureFun.Contiguous.biterate(Val{6}())
PureFun.Tries.@Trie BitMapTrie128 PureFun.Contiguous.bitmap(Val{128}()) PureFun.Contiguous.biterate(Val{7}())

BitMapTrie = Union{BitMapTrie8,
                   BitMapTrie16,
                   BitMapTrie32,
                   BitMapTrie64,
                   BitMapTrie128}

struct HashMap{T,K,V} <: PureFun.PFDict{K,V} where {T <: BitMapTrie}
    trie::T
    function HashMap{T,K,V}() where {K,V,T<:BitMapTrie}
        new{T,K,V}(T())
    end
    HashMap{T,K,V}(trie) where {T,K,V} = new{T,K,V}(trie)
end

Bucket{K,V} = PureFun.Association.List{K, V} where {K,V}

HashMap8{K,V}   = HashMap{   BitMapTrie8{ UInt, Bucket{K,V} }, K,V } where {K,V}
HashMap16{K,V}  = HashMap{  BitMapTrie16{ UInt, Bucket{K,V} }, K,V } where {K,V}
HashMap32{K,V}  = HashMap{  BitMapTrie32{ UInt, Bucket{K,V} }, K,V } where {K,V}
HashMap64{K,V}  = HashMap{  BitMapTrie64{ UInt, Bucket{K,V} }, K,V } where {K,V}
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

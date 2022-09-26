module HashTable

using ..PureFun

# Bits: a single-integer bitset that stores small integers {{{

struct Bits{T<:Unsigned}
    x::T
end

Bits{T}() where T = Bits(zero(T))

bits(b::Bits) = b.x
Base.bitstring(x::Bits) = Base.bitstring(bits(x))
tp(::Type{<:Bits{T}}) where T = T
tp(b::Bits) = tp(typeof(b))
nbits(x::Bits) = sizeof(tp(x)) << 3
nbits(x::DataType) = sizeof(x) << 3
nbits(x) = sizeof(typeof(x)) << 3
Base.show(io::IO, ::MIME"text/plain", x::Bits) = println(bitstring(x))
Base.empty(b::Bits) = Bits(zero(bits(b)))
Base.eltype(::Type{<:Bits}) = Int

Base.isempty(b::Bits) = iszero(bits(b))

one_at(i, T::Type{<:Unsigned}) = one(T) << (i-1)
ones_until(T, i) = ~zero(T) >> (nbits(T) - i)

isoccupied(x::Bits, i) = !iszero(one_at(i, tp(x)) & bits(x))
firstoccupied(x::Bits) = 1 + trailing_zeros(bits(x))
lastoccupied(x::Bits) = nbits(x) - leading_zeros(bits(x))
whichind(x::Bits, i) =  count_ones(ones_until(tp(x), i) & bits(x))
setbit(x::Bits, i) = Bits(one_at(i, tp(x)) | bits(x))
function unsetbit(x::Bits, i)
    mask = ~one_at(i, tp(x))
    Bits(mask & bits(x))
end

Base.length(x::Bits) = count_ones(bits(x))

function Base.iterate(x::Bits)
    iszero(bits(x)) && return nothing
    i1 = firstoccupied(x)
    i1, unsetbit(x, i1)
end
function Base.iterate(x::Bits, state)
    iszero(bits(state)) && return nothing
    i1 = firstoccupied(state)
    i1, unsetbit(state, i1)
end

# }}}

# bitmap: maps small integer keys to values {{{
struct BitMap{B<:Bits, K<:Integer, V, L <: PureFun.PFList{V}} <: PureFun.PFDict{K, V}
    b::B
    elems::L
    function BitMap{B,K,V,L}() where {B,K,V,L}
        new{B,K,V,L}(B(), L())
    end
    function BitMap(b, elems)
        new{typeof(b), Int, eltype(elems), PureFun.container_type(elems)}(b,elems)
    end
end

inds(bm::BitMap) = bm.b
elems(bm::BitMap) = bm.elems

function bitmap(n_elems=16, ListType = PureFun.VectorCopy.List)
    U = _uint_with_bits(n_elems)
    BitMap{Bits{U}, K, V, ListType{V}} where {K,V}
end

function Base.get(bm::BitMap, ix, default)
    isoccupied(inds(bm), ix) || return default
    i = whichind(inds(bm), ix)
    @inbounds elems(bm)[i]
end

function Base.setindex(bm::BitMap, v, ix)
    @boundscheck ix > nbits(inds(bm)) && throw(BoundsError(bm, ix))
    hasind = isoccupied(inds(bm), ix)
    b = setbit(inds(bm), ix)
    at = whichind(b, ix)
    el = hasind ? setindex(elems(bm), v, at) : insert(elems(bm), at, v)
    BitMap(b, el)
end

Base.isempty(bm::BitMap) = isempty(inds(bm))
function Base.empty(bm::BitMap)
    BitMap( empty(inds(bm)),
            empty(elems(bm)) )
end

function _uint_with_bits(bits)
    if bits == 8
        UInt8
    elseif bits == 16
        UInt16
    elseif bits == 32
        UInt32
    elseif bits == 64
        UInt64
    elseif bits == 128
        UInt128
    else
        throw(ErrorException("`bits` must be 8, 16, 32, 64, or 128"))
    end
end


function Base.iterate(bm::BitMap)
    ix = iterate(inds(bm))
    el = iterate(elems(bm))
    ix === nothing && return nothing
    el === nothing && return nothing
    Pair(ix[1], el[1]), (ix[2], el[2])
end
function Base.iterate(bm::BitMap, state)
    ix = iterate(inds(bm), state[1])
    el = iterate(elems(bm), state[2])
    ix === nothing && return nothing
    el === nothing && return nothing
    Pair(ix[1], el[1]), (ix[2], el[2])
end

Base.length(bm::BitMap) = length(inds(bm))
PureFun.push(bm::BitMap, pair) = setindex(bm, pair[2], pair[1])

# }}}

# Bit-eration: iterate 64-bit hashes as a sequence of small ints {{{

"""
    Biterable{N,T}

take an unsigned integer of type T and iterate over it N bits at a time. The
iterated elements are returned as unsigned integers (e.g. if N = 8, then
Biterable will iterate UInt8)
"""
struct Biterable{N, T<:Unsigned}
    x::T
end

function Base.iterate(b::Biterable{N,T}) where {N,T}
    mask = ~zero(b.x) >>> (nbits(T) - N)
    nxt = 1+reinterpret(Int, b.x & mask)
    fin = div(8*sizeof(T), N)
    nxt, (mask << N, 1, fin)
end

function Base.iterate(b::Biterable{N,T}, state) where {N,T}
    mask, k, fin = state
    k >= fin && return nothing
    nxt = 1+reinterpret(Int, (b.x & mask) >>> (k*N))
    nxt, (mask << N, k+1, fin)
end

function Base.getindex(b::Biterable{N,T}, ix) where {N,T}
    i = ix - 1
    shifted_mask = ~zero(b.x) >>> (nbits(T) - N)
    mask = shifted_mask << (i*N)
    1+reinterpret(Int, (b.x & mask) >> (i*N))
end

Base.length(b::Biterable{N,T}) where {N,T} = div(nbits(T), N)
Base.firstindex(b::Biterable) = 1
Base.lastindex(b::Biterable) = length(b)
Base.eltype(::Type{<:Biterable}) = Int

biterate(x, ::Val{N}) where N = Biterable{N, typeof(x)}(x)

# }}}

# key type (container to hold key and iterable hash): {{{

struct HashedKey{K, N}
    #key::K
    hash::Biterable{N, UInt64}
end
Base.show(io::IO, m::MIME"text/plain", x::HashedKey) = println(io, x.hash)
Base.show(io::IO,  x::HashedKey) = print(io, x.hash)

function HashedKey{K, N}(k::K) where {K,N}
    HashedKey{K,N}(biterate(hash(k), Val{N}()))
end

function HashedKey(k, v::Val{N}) where N
    HashedKey{typeof(k), N}(biterate(hash(k), v))
end

Base.iterate(x::HashedKey) = iterate(x.hash)
Base.iterate(x::HashedKey, state) = iterate(x.hash, state)
Base.length(x::HashedKey) = length(x.hash)
Base.eltype(::Type{<:HashedKey}) = Int
Base.getindex(x::HashedKey, i) = x.hash[i]
Base.firstindex(x::HashedKey) = 1
Base.lastindex(x::HashedKey) = length(x)

# }}}

# the hash map {{{

PureFun.Tries.@Trie HashTrie8   bitmap(8)
PureFun.Tries.@Trie HashTrie16  bitmap(16)
PureFun.Tries.@Trie HashTrie32  bitmap(32)
PureFun.Tries.@Trie HashTrie64  bitmap(64)
PureFun.Tries.@Trie HashTrie128 bitmap(128)

HashTrie = Union{HashTrie8, HashTrie16, HashTrie32, HashTrie64, HashTrie128}

struct HashMap{T,K,V} <: PureFun.PFDict{K,V} where {T <: HashTrie}
    trie::T
    function HashMap{T,K,V}() where {K,V,T<:HashTrie}
        new{T,K,V}(T())
    end
    HashMap{T,K,V}(trie) where {T,K,V} = new{T,K,V}(trie)
end

Bucket{K,V} = PureFun.AList.Map{PureFun.Linked.List{Pair{K,V}}, K, V} where {K,V}

HashMap8{K,V}   = HashMap{ HashTrie8{  HashedKey{K,3}, Int, Bucket{K,V} }, K,V } where {K,V}
HashMap16{K,V}  = HashMap{ HashTrie16{ HashedKey{K,4}, Int, Bucket{K,V} }, K,V } where {K,V}
HashMap32{K,V}  = HashMap{ HashTrie32{ HashedKey{K,5}, Int, Bucket{K,V} }, K,V } where {K,V}
HashMap64{K,V}  = HashMap{ HashTrie64{ HashedKey{K,6}, Int, Bucket{K,V} }, K,V } where {K,V}
HashMap128{K,V} = HashMap{ HashTrie64{ HashedKey{K,7}, Int, Bucket{K,V} }, K,V } where {K,V}

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

function hasher(m::HashMap)
    keytype(m.trie)
end

function Base.get(m::HashMap, key, default)
    k = hasher(m)(key)
    bucket = get(m.trie, k, Bucket{keytype(m), valtype(m)}())
    get(bucket, key, default)
end

function Base.setindex(m::HashMap, val, key)
    k = hasher(m)(key)
    nu = update_at(m.trie, k, Bucket{keytype(m), valtype(m)}()) do bucket
        setindex(bucket, val, key)
    end
    typeof(m)(nu)
end

PureFun.push(m::HashMap, kv) = setindex(m, kv.second, kv.first)

Base.IteratorSize(m::HashMap) = Base.SizeUnknown()

# }}}

end

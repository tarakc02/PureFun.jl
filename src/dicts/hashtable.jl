module HashTable

using ..PureFun

# Bits: a single-integer bitset that stores small integers {{{

struct Bits{T}
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

one_at(i, ::Type{T}) where T = one(T) << (i-1)
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

function bitmap(n_elems::Val=Val{16}(), LT::Type{ListType}=PureFun.VectorCopy.List) where ListType
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

function _uint_with_bits(::Val{bits}) where bits
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
    Biterate{N,T}

take an unsigned integer of type T and iterate over it N bits at a time. The
iterated elements are returned as unsigned integers (e.g. if N = 8, then
Biterate will iterate UInt8)
"""
struct Biterate{N, T}
    x::T
    Biterate{N,T}(x) where {N,T} = new{N,T}(x)
    Biterate{N}(x) where {N} = new{N,typeof(x)}(x)
end

function Base.iterate(b::Biterate{N,T}) where {N,T}
    mask = ~zero(b.x) >>> (nbits(T) - N)
    nxt = one(T) + (b.x & mask)
    fin = T(div(8*sizeof(T), N))
    nxt, (mask << N, one(T), fin)
end

function Base.iterate(b::Biterate{N,T}, state) where {N,T}
    mask, k, fin = state
    k >= fin && return nothing
    nxt = one(T) + ((b.x & mask) >>> (k*N))
    nxt, (mask << N, k+one(T), fin)
end

function Base.getindex(b::Biterate{N,T}, ix) where {N,T}
    i = ix - 1
    shifted_mask = ~zero(b.x) >>> (nbits(T) - N)
    mask = shifted_mask << (i*N)
    1+reinterpret(Int, (b.x & mask) >> (i*N))
end

Base.length(b::Biterate{N,T}) where {N,T} = div(nbits(T), N)
Base.firstindex(b::Biterate) = 1
Base.lastindex(b::Biterate) = length(b)
Base.eltype(::Type{<:Biterate}) = Int

biterate(::Val{N}, x) where N = Biterate{N, typeof(x)}(x)
biterate(v::Val{N}) where N = Biterate{N}

# }}}

# the hash map {{{

# tries that convert inputs to iterators over ints, and use bitmaps as the
# edgemaps
PureFun.Tries.@Trie BitMapTrie8   bitmap(Val{8}())   biterate(Val{3}())
PureFun.Tries.@Trie BitMapTrie16  bitmap(Val{16}())  biterate(Val{4}())
PureFun.Tries.@Trie BitMapTrie32  bitmap(Val{32}())  biterate(Val{5}())
PureFun.Tries.@Trie BitMapTrie64  bitmap(Val{64}())  biterate(Val{6}())
PureFun.Tries.@Trie BitMapTrie128 bitmap(Val{128}()) biterate(Val{7}())

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

Bucket{K,V} = PureFun.Association.Map{PureFun.Linked.List{Pair{K,V}}, K, V} where {K,V}

HashMap8{K,V}   = HashMap{   BitMapTrie8{ UInt, Int, Bucket{K,V} }, K,V } where {K,V}
HashMap16{K,V}  = HashMap{  BitMapTrie16{ UInt, Int, Bucket{K,V} }, K,V } where {K,V}
HashMap32{K,V}  = HashMap{  BitMapTrie32{ UInt, Int, Bucket{K,V} }, K,V } where {K,V}
HashMap64{K,V}  = HashMap{  BitMapTrie64{ UInt, Int, Bucket{K,V} }, K,V } where {K,V}
HashMap128{K,V} = HashMap{ BitMapTrie128{ UInt, Int, Bucket{K,V} }, K,V } where {K,V}

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

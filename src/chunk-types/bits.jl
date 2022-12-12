
# Bits: a single-integer bitset that stores small integers {{{

@doc raw"""

A sparse set with small integer elements.

# Examples

```jldoctest
julia> b = PureFun.Contiguous.Bits{UInt16}()
0000000000000000

# the 1s in the bitstring mark the elements that are present
julia> b = reduce(push, [1,9,4,15,15], init=b)
0100000100001001


julia> 15 ∈ b, 4 ∈ b, 2 ∈ b
(true, true, false)
```
"""
struct Bits{T} <: PureFun.PFSet{T}
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

PureFun.push(x::Bits, i) = setbit(x, i)
Base.in(i, x::Bits) = isoccupied(x, i)

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
struct BitMap{B<:Bits, K<:Integer, V} <: PureFun.PFDict{K, V}
    b::B
    elems::PureFun.VectorCopy.List{V}
    function BitMap{B,K,V}() where {B,K,V}
        new{B,K,V}(B(), PureFun.VectorCopy.List{V}())
    end
    function BitMap(b, elems, K)
        new{typeof(b), K, eltype(elems)}(b,elems)
    end
end

inds(bm::BitMap) = bm.b
elems(bm::BitMap) = bm.elems

@doc raw"""
    bitmap(n_elems=Val{16}())

Create a BitMap with `n_elems` elements. See also
[`PureFun.Tries.@trie`](@ref). If the number of elements are known at compile
time, then using `Val{N}()` rather than `N` to specify the number might be more
efficient.

# Examples

```jldoctest
julia> using PureFun, PureFun.Contiguous
julia> BM = Contiguous.bitmap(8) # equivalently: Contiguous.bitmap(Val{8}())
PureFun.Contiguous.BitMap{PureFun.Contiguous.Bits{UInt8}}

julia> b = BM{Int,Char}()
PureFun.Contiguous.BitMap{PureFun.Contiguous.Bits{UInt8}, Int64, Char}()

julia> setindex(b, 'a', 1)
PureFun.Contiguous.BitMap{PureFun.Contiguous.Bits{UInt8}, Int64, Char} with 1 entry:
  1 => 'a'
```
"""
function bitmap(n_elems::Val=Val{16}())
    U = _uint_with_bits(n_elems)
    BitMap{Bits{U}}
end
bitmap(n_elems) = bitmap(Val(n_elems))

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
    BitMap(b, el, keytype(bm))
end

Base.isempty(bm::BitMap) = isempty(inds(bm))
function Base.empty(bm::BitMap)
    BitMap( empty(inds(bm)),
            empty(elems(bm)),
            keytype(bm))
end

_uint_with_bits(::Val{8}) = UInt8
_uint_with_bits(::Val{16}) = UInt16
_uint_with_bits(::Val{32}) = UInt32
_uint_with_bits(::Val{64}) = UInt64
_uint_with_bits(::Val{128}) = UInt128

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

struct Biterate{N, T}
    x::T
    Biterate{N,T}(x) where {N,T} = new{N,T}(x)
    Biterate{N}(x) where {N} = new{N,typeof(x)}(x)
end

function Base.iterate(b::Biterate{N,T}) where {N,T}
    mask = ~zero(b.x) >>> (nbits(T) - N)
    nxt = one(T) + (b.x & mask)
    fin = T(cld(8*sizeof(T), N))
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
    1+convert(Int, (b.x & mask) >> (i*N))
end

Base.length(b::Biterate{N,T}) where {N,T} = cld(nbits(T), N)
Base.firstindex(b::Biterate) = 1
Base.lastindex(b::Biterate) = length(b)
Base.eltype(::Type{<:Biterate}) = Int

@doc raw"""
    biterate(v)
    biterate(v, x)

take an integer and iterate over it N bits at a time. The iterated elements are
interpreted as integers between 1 and $2^v$ (e.g. if `v` = 6, then biterate
will iterate integers between 1 and 64). The iterated integers are meant to be
interpreted as array indexes, and are are always greater than 0.

If the number of bits `v` is known at compile-time, specifying it as `Val{N}()`
might be more efficient than just passing the number as an integer.

# Examples

```jldoctest
julia> using PureFun, PureFun.Contiguous
julia> Contiguous.biterate(4, UInt16(79)) |> collect
4-element Vector{Int64}:
 16
  5
  1
  1
```
"""
biterate(::Val{N}, x) where N = Biterate{N, typeof(x)}(x)
biterate(v::Val{N}) where N = Biterate{N}
biterate(v) = biterate(Val(v))
biterate(v, x) = biterate(Val(v), x)

# }}}

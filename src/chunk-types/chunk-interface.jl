@doc raw"""
`PureFun.Contiguous` implements small-sized versions of lists, sets, and
dictionaries. These structures maintain data in contiguous storage, allowing
them to leverage the [CPU cache](https://en.wikipedia.org/wiki/CPU_cache) to
improve the performance of indexing and iteration.
"""
module Contiguous

using ..PureFun
using ..PureFun.VectorCopy
using StaticArrays

# type defs {{{
abstract type Chunk{N,T} <: PureFun.PFList{T} where N end

@doc raw"""

    StaticChunk{N,T}
    StaticChunk{N}(iter)

Backed by [Static
Arrays](https://juliaarrays.github.io/StaticArrays.jl/stable/), `StaticChunks`
implement all list functions but are constrained to a maximum size. Useful in
conjunction with `PureFun.Chunky.@list`, which chains together small chunks to
build general list types that benefit from [data
locality](https://gameprogrammingpatterns.com/data-locality.html).

# Examples

This example builds a list with maximum length 8. Until we hit the maximum
length, we can use the `StaticChunk` like any other list type:

```jldoctest
julia> xs = Contiguous.StaticChunk{8}(1:3)
3-element PureFun.Contiguous.StaticChunk{8, Int64}
1
2
3

julia> 41 ⇀ 42 ⇀ xs
5-element PureFun.Contiguous.StaticChunk{8, Int64}
41
42
1
2
3

julia> popfirst(xs)
2-element PureFun.Contiguous.StaticChunk{8, Int64}
2
3
```
"""
struct StaticChunk{N,T} <: Chunk{N,T}
    v::SVector{N,T}
    head::Int
    StaticChunk(v::SVector{N,T}, head) where {N,T} = new{N,T}(v, head)
    StaticChunk{N,T}(v::SVector{N,T}, head) where {N,T} = new{N,T}(v, head)
    function StaticChunk{N,T}(iter) where {N,T}
        if length(iter) == N
            return new{N,T}(SVector{N}(iter), 1)
        else
            len = length(iter)
            rem = N - len
            out = vcat(Vector{T}(undef, rem), collect(iter))
            return new{N,T}(SVector{N}(out), rem+1)
        end
    end
    StaticChunk{N}(iter) where N = StaticChunk{N,eltype(iter)}(iter)
end

@doc raw"""

    VectorChunk{N,T}
    VectorChunk{N}(iter)

Backed by `Base.Vector`, `VectorChunk`s implement all list functions but are
constrained to a maximum size. Useful in conjunction with
`PureFun.Chunky.@list`, which chains together small chunks to build general
list types that benefit from [data
locality](https://gameprogrammingpatterns.com/data-locality.html).

# Examples

This example builds a list with maximum length 128. Until we hit the maximum
length, we can use the `VectorChunk` like any other list type:

```jldoctest
julia> using PureFun, PureFun.Contiguous
julia> xs = Contiguous.VectorChunk{128}(1:3)
3-element PureFun.Contiguous.VectorChunk{128, Int64}
1
2
3


julia> (41 ⇀ 42 ⇀ xs) ⧺ xs
8-element PureFun.Contiguous.VectorChunk{128, Int64}
41
42
1
2
3
1
2
...

```
"""
struct VectorChunk{N,T} <: Chunk{N,T}
    v::VectorCopy.List{T}
    VectorChunk{N,T}() where {N,T} = new{N,T}(VectorCopy.List{T}())
    VectorChunk{N}(v::VectorCopy.List) where N = new{N,eltype(v)}(v)
    VectorChunk{N,T}(v::VectorCopy.List{T}) where {N,T} = new{N,T}(v)
    VectorChunk{N,T}(iter) where {N,T} = new{N,T}(VectorCopy.List(iter))
    function VectorChunk{N}(iter) where N
        v = VectorCopy.List(iter)
        T = eltype(v)
        new{N,T}(v)
    end
end

Base.IteratorSize(::Type{<:Chunk}) = Base.HasLength()

# }}}

# Basic list ops {{{
Base.isempty(xs::StaticChunk) = xs.head > chunksize(xs)
Base.isempty(xs::VectorChunk) = isempty(xs.v)
Base.empty(xs::StaticChunk)   = StaticChunk(xs.v, chunksize(xs) + 1)
Base.empty(xs::VectorChunk)   = VectorChunk{chunksize(xs)}(empty(xs.v))

function initval(x, C::Type{<:StaticChunk})
    N = chunksize(C)
    StaticChunk(@SVector(fill(x, N)), N)
end

function initval(x, C::Type{<:VectorChunk})
    N = chunksize(C)
    VectorChunk{N}([x])
end

function PureFun.cons(x, xs::StaticChunk)
    StaticChunk(setindex(xs.v, x, xs.head-1), xs.head-1)
end
function PureFun.cons(x, xs::VectorChunk)
    VectorChunk{chunksize(xs)}(cons(x, xs.v))
end

function PureFun.head(xs::StaticChunk)
    @boundscheck isempty(xs) && throw(BoundsError(xs, 1))
    @inbounds xs.v[xs.head]
end
function PureFun.head(xs::VectorChunk)
    @boundscheck isempty(xs.v) && throw(BoundsError(xs, 1))
    @inbounds first(xs.v)
end

PureFun.tail(xs::StaticChunk) = StaticChunk(xs.v, xs.head+1)
PureFun.tail(xs::VectorChunk) = VectorChunk{chunksize(xs)}(tail(xs.v))
# }}}

# manage chunk size {{{
chunksize(::Chunk{N}) where N = N::Int
chunksize(::Type{<:Chunk{N}}) where N = N::Int

nearempty(xs::StaticChunk) = xs.head == chunksize(xs)
nearempty(xs::VectorChunk) = length(xs.v) <= 1
isfull(xs::StaticChunk) = xs.head < 2
isfull(xs::VectorChunk) = length(xs.v) >= chunksize(xs)
# }}}

# other methods (length, indexing) {{{
Base.length(xs::StaticChunk) = chunksize(xs) - xs.head + 1
Base.length(xs::VectorChunk) = length(xs.v)

Base.getindex(xs::StaticChunk, i::Integer) = xs.v[xs.head+i-1]
Base.getindex(xs::VectorChunk, i::Integer) = xs.v[i]

function Base.setindex(xs::StaticChunk, val, i::Integer)
    StaticChunk(setindex(xs.v, val, xs.head+i-1), xs.head)
end

function Base.setindex(xs::VectorChunk, val, i)
    VectorChunk{chunksize(xs)}(setindex(xs.v, val, i))
end

function Base.reverse(xs::VectorChunk)
    isempty(xs) ? xs : VectorChunk{chunksize(xs)}(reverse(xs.v))
end

function _rev_from(v, h)
    out = MVector(v)
    l = length(v)
    for i in h:l
        out[i] = v[l-i+h]
    end
    typeof(v)(out)
end

function Base.reverse(xs::StaticChunk)
    isempty(xs) && return xs
    StaticChunk(_rev_from(xs.v, xs.head), xs.head)
end

# assumes that `isfull(xs)`
function reverse_fast(xs::StaticChunk)
    isempty(xs) && return xs
    typeof(xs)(reverse(xs.v), xs.head)
end
reverse_fast(xs::VectorChunk) = reverse(xs)

# }}}

_mr_first(f, op, chunk::StaticChunk) = mapreduce(f, op, @view chunk.v[chunk.head:end])
_mr_rest(f, op, chunk::StaticChunk) = mapreduce(f, op, chunk.v)
_mr_first(f, op, chunk::VectorChunk) = mapreduce(f, op, chunk.v)
_mr_rest(f, op, chunk::VectorChunk) = mapreduce(f, op, chunk.v.vec)

Base.map(f, chunk::VectorChunk) = VectorChunk{chunksize(chunk)}(map(f, chunk.v))
function Base.map(f, chunk::StaticChunk)
    out = map(f, chunk.v)
    StaticChunk{chunksize(chunk), eltype(out)}(out, chunk.head)
end

# iteration {{{
function Base.iterate(c::Chunk)
    isempty(c) ? nothing : @inbounds c[1], (2, length(c))
end
function Base.iterate(c::Chunk, state)
    cur, fin = state[1], state[2]
    cur > fin ? nothing : (@inbounds c[cur], (cur+1, fin))
end
# }}}

include("bits.jl")

end


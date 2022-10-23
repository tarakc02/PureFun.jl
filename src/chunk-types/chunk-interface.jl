module Contiguous

using ..PureFun
using ..PureFun.VectorCopy
using StaticArrays

# type defs {{{
abstract type Chunk{N,T} <: PureFun.PFList{T} where N end

struct StaticChunk{N,T} <: Chunk{N,T}
    v::SVector{N,T}
    head::Int
    function StaticChunk{N,T}() where {N,T}
        new{N,T}(SVector{N,T}(Vector{T}(undef, N)), N+1)
    end
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
    @inbounds xs.v[1]
end

PureFun.tail(xs::StaticChunk) = StaticChunk(xs.v, xs.head+1)
PureFun.tail(xs::VectorChunk) = VectorChunk{chunksize(xs)}(tail(xs.v))
# }}}

# manage chunk size {{{
chunksize(::Chunk{N}) where N = N::Int
chunksize(::Type{<:Chunk{N}}) where N = N::Int

nearempty(xs::StaticChunk) = xs.head == chunksize(xs)
nearempty(xs::VectorChunk) = length(xs.v) == 1
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
# }}}

_mr_first(f, op, chunk::StaticChunk) = mapreduce(f, op, @view chunk.v[chunk.head:end])
_mr_rest(f, op, chunk::StaticChunk) = mapreduce(f, op, chunk.v)
_mr_first(f, op, chunk::VectorChunk) = mapreduce(f, op, chunk.v)
_mr_rest(f, op, chunk::VectorChunk) = mapreduce(f, op, chunk.v)

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

end


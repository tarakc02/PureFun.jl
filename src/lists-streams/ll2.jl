module Unrolled
using ..PureFun
using StaticArrays

# Chunks {{{
struct Chunk{N,T} <: PureFun.PFList{T}
    v::SVector{N,T}
    head::Int
end

PureFun.cons(x, xs::Chunk) = Chunk(setindex(xs.v, x, xs.head-1), xs.head-1)
PureFun.head(xs::Chunk) = xs.v[xs.head]
PureFun.tail(xs::Chunk) = Chunk(xs.v, xs.head+1)
Base.isempty(xs::Chunk) = xs.head > chunksize(xs)
Base.empty(xs::Chunk) = Chunk(xs.v, chunksize(xs) + 1)
Base.length(xs::Chunk) = chunksize(xs) - xs.head + 1
nearempty(xs::Chunk) = xs.head == chunksize(xs)
isfull(xs::Chunk) = xs.head < 2
Chunk{N,T}() where {N,T} = Chunk{N,T}(SVector{N,T}(Vector{T}(undef, N)), N+1)
chunksize(::Chunk{N}) where N = N
chunksize(::Type{<:Chunk{N}}) where N = N

Base.iterate(c::Chunk) = c.v[c.head], c.head+1
Base.iterate(c::Chunk{N}, state) where N = state > N ? nothing : (c.v[state], state+1)

function Base.getindex(xs::Chunk, i::Integer)
    i > length(xs) ?
        throw(BoundsError(xs, i)) :
        xs.v[xs.head+i-1]
end

function Base.setindex(xs::Chunk, val, i::Integer)
    i > length(xs) ?
        throw(BoundsError(xs, i)) :
        Chunk(setindex(xs.v, val, xs.head+i-1), xs.head)
end
# }}}

struct List{N,T} <: PureFun.PFList{T} where {N}
    chunks::PureFun.Linked.List{ Chunk{N,T} }
end

chunksize(::List{N,T}) where {N,T} = N
chunksize(::Type{<:List{N,T}}) where {N,T} = N
chunksize(::PureFun.PFList{Chunk{N,T}}) where {N,T} = N
chunksize(::Type{<:PureFun.PFList{Chunk{N,T}}}) where {N,T} = N

function List{N}(iter) where {N}
    foldr(cons, iter, init=List{N,eltype(iter)}())
end

List{N,T}() where {N,T} = List(PureFun.Linked.List{Chunk{N,T}}())

Base.isempty(l::List) = isempty(l.chunks)
Base.empty(l::List) = List(empty(l.chunks))

function initval(x, xs::List{N,T}) where {N,T}
    chnk = cons(x, Chunk{N,T}())
    List(cons(chnk, xs.chunks))
end

function PureFun.cons(x, xs::List)
    isempty(xs) && return initval(x, xs)
    chunks = xs.chunks
    chunk = head(chunks)
    if isfull(head(chunks))
        newchunk = cons(x, empty(chunk))
        List(cons(newchunk, chunks))
    else
        List(cons( cons(x,chunk) , tail(chunks) ))
    end
end

function PureFun.tail(xs::List)
    isempty(xs) && throw("Empty List")
    chunks = xs.chunks
    hd = head(chunks)
    nearempty(hd) ?
        List(tail(chunks)) :
        List(cons( tail(hd), tail(chunks) ))
end

PureFun.head(xs::List) = head(head(xs.chunks))

function Base.iterate(l::List{N,T}) where {N,T}
    isempty(l) && return nothing
    chunks = l.chunks::PureFun.Linked.NonEmpty{Chunk{N,T}}
    head(l), (chunks, head(chunks).head)
end

function Base.iterate(::List{N,T}, state) where {N,T}
    chunks = state[1]::PureFun.Linked.NonEmpty{Chunk{N,T}}
    index = state[2]+1
    chunk = head(chunks)
    if index > chunksize(chunk)
        chunks = tail(chunks)
        isempty(chunks) && return nothing
        chunk = head(chunks)
        return head(chunk), (chunks::PureFun.Linked.NonEmpty{Chunk{N,T}}, chunk.head)
    else
        return chunk.v[index], (chunks::PureFun.Linked.NonEmpty{Chunk{N,T}}, index)
    end
end

function chunkindex(ind, N, headlen)
    ind <= headlen && return (1, ind)
    newind = ind - headlen
    skip, chunkind = divrem(newind, N)
    chunkind == 0 ? (1+skip, N) : (2+skip, chunkind)
end

function Base.getindex(l::List, ind)
    isempty(l) && throw(BoundsError(l, ind))
    chunk, subind = chunkindex(ind, chunksize(l), length(head(l.chunks)))
    l.chunks[chunk][subind]
end

function Base.setindex(l::List, val, ind)
    List(_setind(l.chunks, val, ind))
end

function _setind(l, val, ind)::typeof(l)
    (isempty(l) || ind < 0) && throw(BoundsError(l, ind))
    if ind > length(head(l))
        cons(head(l), _setind(tail(l), val, ind-length(head(l))))
    else
        cons(setindex(head(l), val, ind), tail(l))
    end
end

function Base.length(l::List)
    isempty(l) ? 0 : sum(length(chunk) for chunk in l.chunks)
end

function PureFun.append(l1::List, l2::List)
    List(l1.chunks ⧺ l2.chunks)
end

end

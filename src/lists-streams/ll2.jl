module Unrolled
using ..PureFun
using ..PureFun.Linked
using StaticArrays

struct Chunk{N,T} <: PureFun.PFList{T}
    v::SVector{N,T}
    head::Int
end

PureFun.cons(x, xs::Chunk) = Chunk(setindex(xs.v, x, xs.head-1), xs.head-1)
PureFun.head(xs::Chunk) = xs.v[xs.head]
PureFun.tail(xs::Chunk) = Chunk(xs.v, xs.head+1)
Base.isempty(xs::Chunk) = xs.head > chunksize(xs)
Base.length(xs::Chunk) = chunksize(xs) - xs.head + 1
nearempty(xs::Chunk) = xs.head == chunksize(xs)
isfull(xs::Chunk) = xs.head < 2
Chunk{N,T}() where {N,T} = Chunk{N,T}(SVector{N,T}(Vector{T}(undef, N)), N+1)
chunksize(::Chunk{N}) where {N} = N

Base.iterate(c::Chunk) = c.v[c.head], c.head+1
Base.iterate(c::Chunk{N}, state) where N = state > N ? nothing : (c.v[state], state+1)

List{N,T} = Linked.List{ Chunk{N,T} } where {N,T}
E{N,T} = Linked.Empty{ Chunk{N,T} } where {N,T}
NE{N,T} = Linked.NonEmpty{ Chunk{N,T} } where {N,T}

function PureFun.cons(x::T, xs::E{N,T}) where {N,T}
    chnk = cons(x, Chunk{N,T}())
    cons(chnk, xs)
end

function PureFun.cons(x::T, xs::NE{N,T}) where {N,T}
    if isfull(xs.head)
        newchunk = cons(x, Chunk{N,T}())
        cons(newchunk, xs)
    else
        cons( cons(x,xs.head) , xs.tail )
    end
end

function PureFun.tail(xs::NE)
    if nearempty(xs.head)
        l = xs.tail
        isempty(l) && return empty(xs)
        return l
    else
        hd = xs.head
        cons( tail(hd), xs.tail )
    end
end

PureFun.head(xs::NE) = head(xs.head)

function List{N}(iter) where N
    foldl(PureFun.push, reverse(iter); init=List{N,eltype(iter)}())
end

Base.eltype(xs::List{N,T}) where {N,T} = T

function Base.iterate(xs::NE)
    #head(xs), (xs, xs.head, xs.head.head)
    head(xs), (xs, xs.head.head)
end

function Base.iterate(list::NE, state)
    xs = state[1]
    #chunk = state[2]
    #index = state[3]+1
    index = state[2]+1
    if index > chunksize(xs.head)
        xs = xs.tail
        isempty(xs) && return nothing
        #return head(xs), (xs, xs.head, xs.head.head)
        return head(xs), (xs, xs.head.head)
    else
        #return xs.head.v[index], (xs, chunk, index)
        return xs.head.v[index], (xs, index)
    end
end

function Base.getindex(l::NE, ind)
    while ind > length(l.head)
        ind -= length(l.head)
        l = l.tail
        ind < 0 && throw(BoundsError(l, ind))
        isempty(l) && throw(BoundsError(l, ind))
    end
    l.head.v[l.head.head + ind - 1]
end

function PureFun.setindex(l::NE, ind, val)
    (isempty(l) || ind < 0) && throw(BoundsError(l, ind))
    if ind > length(l.head)
        cons(l.head, PureFun.setindex(l.tail, ind-length(l.head), val))
    else
        cons(Chunk(setindex(l.head.v, val, ind), l.head.head), l.tail)
    end
end

Base.length(l::E) = 0
Base.length(l::NE) = sum(length(chunk) for chunk in l)

end

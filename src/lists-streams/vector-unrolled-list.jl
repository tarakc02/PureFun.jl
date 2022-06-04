module Unrolled

using ..PureFun
using ..PureFun.Linked
using ..PureFun.VectorCopy

struct Chunk{N,T} <: PureFun.PFList{T}
    v::VectorCopy.List{T}
end

Chunk{N,T}() where {N,T} = Chunk{N,T}(VectorCopy.List{T}())
Base.length(c::Chunk) = length(c.v)
Base.isempty(c::Chunk) = isempty(c.v)
Base.empty(c::Chunk{N,T}) where {N,T} = Chunk{N,T}(empty(c.v))
PureFun.cons(x::T, xs::Chunk{N,T}) where {N,T} = Chunk{N,T}(cons(x, xs.v))
PureFun.tail(xs::Chunk{N,T}) where {N,T} = Chunk{N,T}(tail(xs.v))
PureFun.head(xs::Chunk) = head(xs.v)

isfull(chunk::Chunk{N,T}) where {N,T} = length(chunk) == N
chunksize(::Chunk{N,T}) where {N,T} = N

struct List{N,T} <: PureFun.PFList{T} where {N}
    chunks::Linked.List{ Chunk{N,T} }
end

function List{N,T}() where {N,T}
    chunks = Linked.List{Chunk{N,T}}()
    List(chunks)
end

Base.length(l::List) = isempty(l) ? 0 : sum(length(chunk) for chunk in l.chunks)
Base.isempty(l::List) = isempty(l.chunks)
Base.empty(l::List{N,T}) where {N,T} = List{N,T}()

function PureFun.cons(x::T, xs::List{N,T}) where {N,T}
    if isempty(xs.chunks)
        chunk = cons(x, Chunk{N,T}())
        list = cons(chunk, Linked.List{Chunk{N,T}}())
        return List(list)
    end
    head_chunk = head(xs.chunks)
    if isfull(head_chunk)
        newchunk = cons(x, Chunk{N,T}())
        List(cons(newchunk, xs))
    else
        List(cons( cons(x,head_chunk) , tail(xs.chunks) ))
    end
end

function PureFun.tail(xs::List)
    new_head = tail(head(xs.chunks))
    isempty(new_head) && return List(tail(xs.chunks))
    List(cons(new_head, tail(xs.chunks)))
end

PureFun.head(xs::List) = isempty(xs) ? throw(BoundsError(xs, 1)) : head(head(xs.chunks))

List(iter::List) = iter
function List{N}(iter) where N
    peek = first(iter)
    T = typeof(peek)
    partitioned = Iterators.partition(iter, N)
    chunks = collect(Chunk{N,T}(VectorCopy.List(p)) for p in partitioned)
    List{N,T}(Linked.List(chunks))
end

#function Base.iterate(iter::List{N,T}) where {N,T}
#    isempty(iter) && return nothing
#    flat = Iterators.flatten(iter.chunks::Linked.NonEmpty{Unrolled.Chunk{N,T}})
#    nxt = iterate(flat)
#    isnothing(nxt) && return nothing
#    nxt[1], (flat, nxt[2])
#end
#
#function Base.iterate(iter::List, state)
#    nxt = iterate(state[1], state[2])
#    isnothing(nxt) && return nothing
#    nxt[1], (state[1], nxt[2])
#end

function Base.iterate(xs::List)
    isempty(xs.chunks) && return nothing
    head(xs), (xs, head(xs.chunks), )
end
#
#function Base.iterate(list::List, state)
#    xs = state[1]
#    chunk = state[2]
#    index = state[3]+1
#    if index > chunksize(chunk)
#        xs = tail(xs.chunks)
#        isempty(xs) && return nothing
#        return head(xs), (xs, head(xs.chunks), head(head(xs.chunks)))
#    else
#        return head(xs.chunks).v.vec[index], (xs, chunk, index)
#    end
#end

end

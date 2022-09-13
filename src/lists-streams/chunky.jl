module Chunky

using ..PureFun
using StaticArrays

# Chunks {{{
struct Chunk{N,T} <: PureFun.PFList{T}
    v::SVector{N,T}
    head::Int
end

PureFun.cons(x, xs::Chunk) = Chunk(setindex(xs.v, x, xs.head-1), xs.head-1)
PureFun.head(xs::Chunk) = @inbounds xs.v[xs.head]
PureFun.tail(xs::Chunk) = Chunk(xs.v, xs.head+1)
Base.isempty(xs::Chunk) = xs.head > chunksize(xs)
Base.empty(xs::Chunk) = Chunk(xs.v, chunksize(xs) + 1)
#Base.empty(xs::Chunk, eltype) = Chunk{chunksize(xs),eltype}()
Base.length(xs::Chunk) = chunksize(xs) - xs.head + 1
nearempty(xs::Chunk) = xs.head == chunksize(xs)
isfull(xs::Chunk) = xs.head < 2
Chunk{N,T}() where {N,T} = Chunk{N,T}(SVector{N,T}(Vector{T}(undef, N)), N+1)
chunksize(::Chunk{N}) where N = N::Int
chunksize(::Type{<:Chunk{N}}) where N = N::Int

Base.iterate(c::Chunk) = @inbounds c.v[c.head], c.head+1
function Base.iterate(c::Chunk{N}, state) where N
    state > N::Int ? nothing : (@inbounds c.v[state], state+1)
end

function check_chunk_bounds(xs::Chunk, i::Integer)
    i > length(xs) && throw(BoundsError(xs, i))
end
Base.@propagate_inbounds function Base.getindex(xs::Chunk, i::Integer)
    #@boundscheck check_chunk_bounds(xs, i)
    @inbounds xs.v[xs.head+i-1]
end
function Base.setindex(xs::Chunk, val, i::Integer)
    #@boundscheck check_chunk_bounds(xs, i)
    @inbounds Chunk(setindex(xs.v, val, xs.head+i-1), xs.head)
end
# }}}

# list type and helpers {{{
struct List{L,T} <: PureFun.PFList{T} where { N,L<:PureFun.PFList{Chunk{N,T}} }
    chunks::L
end

chunksize(::List{L,T}) where { T,N,L<:PureFun.PFList{Chunk{N,T}} } = N::Int
chunksize(::Type{<:List{L,T}}) where { T,N,L<:PureFun.PFList{Chunk{N,T}} } = N::Int
chunksize(::PureFun.PFList{Chunk{N,T}}) where {N,T} = N::Int
chunksize(::Type{ <:PureFun.PFList{Chunk{N,T}} }) where {N,T} = N::Int

get_et(iter) = eltype(iter)
# }}}

# basic constructors {{{
function chunky(N::Integer, L::UnionAll=PureFun.Linked.List)
    List{ L{Chunk{N,T}}, T} where T
end

List{L,T}() where {L,T} = List(L())

_typedlist(chunks) = List(chunks)
function List(chunks::L) where { N,T,L<:PureFun.PFList{Chunk{N,T}} }
    List{PureFun.container_type(chunks),T}(chunks)
end
# }}}

# construct from an iterable. not sure how to write this generically {{{
function (List{PureFun.RandomAccess.List{Chunk{N,T}},T} where T)(iter) where N
    et = get_et(iter)
    foldr(cons, iter, init=List{PureFun.RandomAccess.List{Chunk{N,et}},et}())
end

function (List{PureFun.Linked.List{Chunk{N,T}},T} where T)(iter) where N
    et = get_et(iter)
    foldr(cons, iter, init=List{PureFun.Linked.List{Chunk{N,et}},et}())
end

function (List{PureFun.Catenable.List{Chunk{N,T}},T} where T)(iter) where N
    et = get_et(iter)
    foldr(cons, iter, init=List{PureFun.Catenable.List{Chunk{N,et}},et}())
end
# }}}

# PFList methods {{{
Base.isempty(l::List) = isempty(l.chunks)
Base.empty(l::List) = _typedlist(empty(l.chunks))
function Base.empty(l::List, eltype) 
    _typedlist(empty(l.chunks, Chunk{chunksize(l), eltype}))
end

function initval(x, xs::List)
    N = chunksize(xs)
    chnk = Chunk{N,eltype(xs)}(@SVector(fill(x, N)), N)
    _typedlist(cons(chnk, xs.chunks))
end

function PureFun.cons(x, xs::List)
    isempty(xs) && return initval(x, xs)
    chunks = xs.chunks
    chunk = head(chunks)
    if isfull(chunk)
        newchunk = cons(x, empty(chunk))
        _typedlist(cons(newchunk, chunks))
    else
        _typedlist(cons( cons(x,chunk) , tail(chunks) ))
    end
end

function PureFun.tail(xs::List)
    isempty(xs) && throw("Empty List")
    chunks = xs.chunks
    hd = head(chunks)
    nearempty(hd) ?
        _typedlist(tail(chunks)) :
        _typedlist(cons( tail(hd), tail(chunks) ))
end

PureFun.head(xs::List) = head(head(xs.chunks))
# }}}

# iteration {{{
function Base.iterate(l::List)
    chunks = l.chunks
    isempty(chunks) ? nothing : (head(l), (chunks, 1, length(head(chunks))))
end

function nxt_head(chunks)
    nxt = tail(chunks)
    isempty(nxt) ?
        nothing :
        (head(head(nxt)), (nxt, 1, length(head(nxt))))
end

function Base.iterate(list::List, state)
    chunks = state[1]
    index = state[2]+1
    len = state[3]
    index > len ?
        nxt_head(chunks) :
        (head(chunks)[index], (chunks, index, len))
end

struct Init end
# }}}

# map + mapreduce specializations {{{
function Base.mapreduce(f, op, xs::List; init=Init())
    isempty(xs) && init isa Init && return Base.reduce_empty(op, eltype(xs))
    isempty(xs) && return init
    func(chunk) = isfull(chunk) ?
        mapreduce(f, op, chunk.v) :
        mapreduce(f, op, @view chunk.v[chunk.head:end])
    out = mapreduce(func, op, xs.chunks)
    init isa Init ? out : op(init, out)
end

function Base.map(f, xs::List)
    T = PureFun.infer_return_type(f, xs)
    N = chunksize(xs)
    func(chunk) = Chunk{N,T}(map(f, chunk.v), chunk.head)
    _typedlist(_map(func, xs.chunks, T))
end

function _map(func, chunks::PureFun.PFList{Chunk{N,T}}, OutType) where {N,T}
    mapfoldr(func, cons, chunks, init=empty(chunks, Chunk{N,OutType}))
end
# }}}

# indexing and length {{{
function Base.getindex(l::List, ind)
    chunks = l.chunks
    isempty(chunks) && throw(BoundsError(l, ind))
    chunk = head(chunks)
    while ind > length(chunk)
        ind -= length(chunk)
        ind < 0 && throw(BoundsError(l, ind))
        chunks = tail(chunks)
        isempty(chunks) && throw(BoundsError(l, ind))
        chunk = head(chunks)
    end
    chunk.v[chunk.head + ind - 1]
end

function Base.setindex(l::List, val, ind)
    _typedlist(_setind(l.chunks, val, ind))
end

function _setind(l, val, ind)::typeof(l)
    (isempty(l) || ind < 0) && throw(BoundsError(l, ind))
    if ind > length(head(l))
        cons(head(l), _setind(tail(l), val, ind-length(head(l))))
    else
        cons(setindex(head(l), val, ind), tail(l))
    end
end

Base.length(l::List) = mapreduce(length, +, l.chunks; init = 0)

# }}}

# specializations: RandomAccess.List {{{

# to preserve the efficiency of getindex/setindex, methods for
# List{<:RandomAccessList} assume that all chunks are full, except possibly the
# first one. Means we won't be able to specialize `append` and `reverse` for
# these, without some additional cleverness
function chunkindex(ind, N, headlen)
    ind <= headlen && return (1, ind)
    newind = ind - headlen
    skip, chunkind = divrem(newind, N)
    chunkind == 0 ? (1+skip, N) : (2+skip, chunkind)
end

function Base.getindex(l::List{<:PureFun.RandomAccess.List}, ind)
    isempty(l) && throw(BoundsError(l, ind))
    chunk, subind = chunkindex(ind, chunksize(l), length(head(l.chunks)))
    @inbounds l.chunks[chunk][subind]
end

# requires traveling to the modified chunk twice, once to retrieve it and
# create the updated chunk, and then to set the new chunk into the resulting
# list of chunks. would be nice if RandomAccess.List had a version of setindex
# that took a function to apply to the current value

function Base.setindex(l::List{<:PureFun.RandomAccess.List}, val, ind)
    isempty(l) && throw(BoundsError(l, ind))
    chunkind, subind = chunkindex(ind, chunksize(l), length(head(l.chunks)))
    @inbounds newchunk = setindex(l.chunks[chunkind], val, subind)
    _typedlist(setindex(l.chunks, newchunk, chunkind))
end

function Base.length(l::List{<:PureFun.RandomAccess.List})
    isempty(l.chunks) ?
        0 :
        length(head(l.chunks)) + chunksize(l) * (length(l.chunks) - 1)
end

# }}}

# specializations for `append` {{{

# neither List{<:Linked.List} or List{<:Catenable.List} require chunks to be
# full, so we can append the chunklists
function PureFun.append(l1::L, l2::L) where {L <: List{<:PureFun.Linked.List}}
    _typedlist(l1.chunks ⧺ l2.chunks)
end

function PureFun.append(l1::L, l2::L) where {L <: List{<:PureFun.Catenable.List}}
    _typedlist(l1.chunks ⧺ l2.chunks)
end
#
# }}}

PureFun.container_type(::Type{<:List{L,T}}) where {L,T} = List{L,T}

end

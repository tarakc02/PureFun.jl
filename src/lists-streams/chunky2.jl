module Chunky

using ..PureFun
using ..PureFun.Contiguous
using ..PureFun.Contiguous: chunksize, isfull, nearempty

function _myname end
function _listname end

# list type and helpers {{{

abstract type List{T} <: PureFun.PFList{T} end

# example usage:
#@list MyList Contiguous.VectorChunk{32} RandomAccess.List
# bloop = MyList{Int}()
macro list(Name, ListType, ChunkType)
    :(
      struct $Name{T} <: List{T}
          chunks::$(esc(ListType)){$(esc(ChunkType)){T}}
          $Name{T}() where T = new{T}( $(esc(ListType)){$(esc(ChunkType)){T}}() )
          $Name{T}(chunks::$(esc(ListType)){$(esc(ChunkType)){T}}) where T = new{T}(chunks)
          $Name(iter) = partition_fill(iter, $Name{Base.@default_eltype(iter)}())
          $Name{T}(iter) where T = partition_fill(iter, $Name{T}())
      end;
      PureFun.Chunky._myname(::$(esc(Name))) = $(esc(Name));
      PureFun.Chunky._listname(::$(esc(Name))) = $(esc(ListType))
     )
end

chunks(l) = l.chunks
Contiguous.chunksize(l::List) = chunksize(eltype(chunks(l)))
chunktype(xs::List) = eltype(chunks(xs))

get_et(iter) = eltype(iter)

empty_chunks = empty ∘ chunks
Base.isempty(l::List) = isempty(chunks(l))
Base.empty(l::List) = typeof(l)(empty_chunks(l))

Base.empty(l::List, ::Type{U}) where U = _myname(l){U}()

# }}}

# PFList methods {{{

function initval(x, xs::List)
    N = chunksize(xs)
    C = chunktype(xs)
    chunk = x ⇀ C()
    typeof(xs)(chunk ⇀ chunks(xs))
end

function PureFun.cons(x, xs::List)
    isempty(xs) && return initval(x, xs)
    cs = chunks(xs)
    chunk = head(cs)
    if isfull(chunk)
        newchunk = x ⇀ empty(chunk)
        typeof(xs)(newchunk ⇀ cs)
    else
        typeof(xs)( (x ⇀ chunk) ⇀ popfirst(cs) )
    end
end

PureFun.tail(xs::List) = _tail(chunks(xs), typeof(xs))

function _tail(cs, L)
    isempty(cs) && throw("Empty List")
    hd = head(cs)
    nearempty(hd) ?
        L(popfirst(cs)) :
        L( popfirst(hd) ⇀ popfirst(cs) )
end

PureFun.head(xs::List) = head(head(chunks(xs)))
# }}}

# initalize from iter {{{

function partition_fill(it, init)
    iter = collect(it)
    len = length(iter)
    leftover = len % chunksize(init)
    front = iter[1:leftover]
    rest = iter[(leftover+1):end]
    cs = Iterators.partition(rest, chunksize(init))
    ct = chunktype(init)
    rem = _listname(init)(Iterators.map(ct, cs))
    typeof(init)(isempty(front) ? rem : ct(front) ⇀ rem)
end

# }}}

# iteration {{{

function Base.iterate(l::List)
    cs = chunks(l)
    isempty(cs) ? nothing : (head(l), (cs, 1, length(head(cs))))
end

function nxt_head(cs)
    nxt = tail(cs)
    isempty(nxt) ?
        nothing :
        (@inbounds head(head(nxt)), (nxt, 1, length(head(nxt))))
end

Base.@propagate_inbounds function Base.iterate(list::List, state)
    cs = state[1]
    index = state[2]+1
    len = state[3]
    index > len ?
        nxt_head(cs) :
        (@inbounds head(cs)[index], (cs, index, len))
end
# }}}

# map + mapreduce specializations {{{
struct Init end

function Base.mapreduce(f, op, xs::List; init=Init())
    isempty(xs) && init isa Init && return Base.reduce_empty(op, eltype(xs))
    isempty(xs) && return init
    cs = chunks(xs)
    rest = popfirst(cs)
    chunk1 = Contiguous._mr_first(f, op, cs[1])
    func(chunk) = Contiguous._mr_rest(f, op, chunk)
    out = isempty(cs) ? chunk1 : op(chunk1, mapreduce(func, op, rest))
    init isa Init ? out : op(init, out)
end

_ctype(l::Type{<:Contiguous.StaticChunk}) = Contiguous.StaticChunk{chunksize(l)}
_ctype(l::Type{<:Contiguous.VectorChunk}) = Contiguous.VectorChunk{chunksize(l)}

function Base.map(f, xs::List)
    func(chunk) = map(f, chunk)
    cs = chunks(xs)
    out = map(func, cs)
    CT = _ctype(eltype(cs))
    OutType = PureFun.infer_return_type(f, xs)
    eltype(out) === CT{OutType} ?
        _myname(xs){eltype(eltype(out))}(out) :
        _myname(xs){Any}(empty(out, CT{Any}))
end

# }}}

# indexing {{{

function chunkindex(ind, N, headlen)
    ind <= headlen && return (1, ind)
    newind = ind - headlen
    skip, chunkind = divrem(newind, N)
    chunkind == 0 ? (1+skip, N) : (2+skip, chunkind)
end

function Base.getindex(l::List, ind)
    isempty(l) && throw(BoundsError(l, ind))
    chunk, subind = chunkindex(ind, chunksize(l), length(head(l.chunks)))
    @inbounds l.chunks[chunk][subind]
end

# requires traveling to the modified chunk twice, once to retrieve it and
# create the updated chunk, and then to set the new chunk into the resulting
# list of chunks. would be nice if RandomAccess.List had a version of setindex
# that took a function to apply to the current value

function Base.setindex(l::List, val, ind)
    isempty(l) && throw(BoundsError(l, ind))
    chunkind, subind = chunkindex(ind, chunksize(l), length(head(l.chunks)))
    @inbounds newchunk = setindex(l.chunks[chunkind], val, subind)
    typeof(l)(setindex(l.chunks, newchunk, chunkind))
end

function Base.length(l::List)
    cs = chunks(l)
    isempty(cs) ? 0 : length(cs[1]) + chunksize(l) * (length(cs) - 1)
end

# }}}

# monolithic stuff (reverse, append) {{{

Base.reverse(l::List) = typeof(l)(reverse!(collect(l)))

function PureFun.append(l1::List, l2::List)
    typeof(l1)(vcat(collect(l1), collect(l2)))
end

# }}}

Base.IteratorSize(::Type{<:List}) = Base.HasLength()

end

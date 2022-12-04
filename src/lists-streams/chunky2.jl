module Chunky

using ..PureFun
using ..PureFun.Contiguous
using ..PureFun.Contiguous: chunksize, isfull, nearempty, initval, reverse_fast
using StaticArrays

function _myname end
function _listname end

# list type and helpers {{{

abstract type List{T} <: PureFun.PFList{T} end

"""
    Chunky.@list Name ListType ChunkType

Creates a new list type (implements all list functions and inherits from
`PureFun.PFList`) by assembling a list (of type `ListType`) of *chunks* (of
type `ChunkType`). Assuming `ChunkType` stores chunk elements contiguously, the
resulting list will have improved iteration performance.
[`PureFun.Contiguous.VectorChunk`](@ref) and
[`PureFun.Contiguous.StaticChunk`](@ref) implement the chunk type and can be
used in chunky lists.

# Examples

This example creates a chunky list called `ChunkyList` consisting of (up to)
16-element chunks stored contiguously in memory as static arrays, linked
together via a linked list. The resulting list has the same interface as any
other list type in PureFun.jl:

```jldoctest
julia> using PureFun, PureFun.Linked, PureFun.Chunky, PureFun.Contiguous

julia> Chunky.@list ChunkyList Linked.List Contiguous.StaticChunk{16}

julia> clist = ChunkyList(1:100)
100-element ChunkyList{Int64}
1
2
3
4
5
6
7
...

julia> clist[18]
18

julia> mapfoldl(sqrt, +, clist)
671.4629471031477
```

Similarly, the following example uses [`PureFun.RandomAccess.List`](@ref)s and
chunks of `Base.Vector`:

```jldoctest
julia> using PureFun, PureFun.RandomAccess, PureFun.Chunky, PureFun.Contiguous

julia> Chunky.@list CRList RandomAccess.List Contiguous.VectorChunk{256}

julia> em = CRList{Float64}()
0-element CRList{Float64}


julia> 1.0 ⇀ 2.0 ⇀ em
2-element CRList{Float64}
1.0
2.0

```

"""
macro list(Name, ListType, ChunkType)
    :(
      struct $Name{T} <: List{T}
          chunks::$(esc(ListType)){$(esc(ChunkType)){T}}
          $Name{T}() where T = new{T}( $(esc(ListType)){$(esc(ChunkType)){T}}() )
          $Name{T}(chunks::$(esc(ListType)){$(esc(ChunkType)){T}}) where T = new{T}(chunks)
          function $Name(iter)
              isempty(iter) && return $Name{Base.@default_eltype(iter)}()
              partition_fill(iter, $Name{Base.@default_eltype(iter)}())
          end
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

function initialize(x, xs::List)
    chunk = initval(x, eltype(chunks(xs)))
    typeof(xs)(chunk ⇀ empty(chunks(xs)))
end

function PureFun.cons(x, xs::List)
    isempty(xs) && return initialize(x, xs)
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


#Base.@propagate_inbounds function Base.iterate(l::List, fullstate=(chunks(l),()))
#    cs = fullstate[1]
#    state = fullstate[2]
#    if state !== ()
#        y = iterate(Base.tail(state)...)
#        y !== nothing && return (y[1], (cs, (state[1], state[2], y[2])))
#    end
#    x = (state === () ? iterate(cs) : iterate(cs, state[1]))
#    x === nothing && return nothing
#    y = iterate(x[1])
#    while y === nothing
#        x = iterate(cs, x[2])
#        x === nothing && return nothing
#        y = iterate(x[1])
#    end
#    return y[1], (cs, (x[2], x[1], y[2]))
#end

function Base._xfadjoint_unwrap(l::List)
    itr′, wrap = Base._xfadjoint_unwrap(chunks(l))
    return itr′, wrap ∘ Base.FlatteningRF
end

function _start_next_chunk(l, cs, st=())
    cs_it = st === () ? iterate(cs) : iterate(cs, st)
    cs_it === nothing && return nothing
    @inbounds c = cs_it[1]
    @inbounds c[1], (cs, cs_it[2], c, 2)
end

_chunkstype(l) = _listname(l){chunktype(l)}

function Base.iterate(l::List)
    _start_next_chunk(l, chunks(l))
end

function Base.iterate(l::List, state)
    cs, c, ix = state[1], state[3], state[4]
    if ix <= length(c)
        @inbounds c[ix], (cs, state[2], c, ix+1)
    else
        @inbounds _start_next_chunk(l, cs, state[2])
    end
end

function Base.filter(f, l::List)
    isempty(l) ? l : typeof(l)(collect(Iterators.filter(f, l)))
end

# }}}

# map + mapreduce specializations {{{
struct Init end

function _mr_empty(f, op, init)
    init isa Init ?
        Base.reduce_empty(op, eltype(xs)) :
        init
end

function _mr_fullchunks(f, op, c1, cs)
    isempty(cs) && return c1
    func(chunk) = Contiguous._mr_rest(f, op, chunk)
    op(c1, mapreduce(func, op, cs))
end

function Base.mapreduce(f, op, xs::List; init=Init())
    isempty(xs) && return _mr_empty(f, op, init)
    cs = chunks(xs)
    chunk1 = Contiguous._mr_first(f, op, first(cs))
    total = _mr_fullchunks(f, op, chunk1, popfirst(cs))
    init isa Init ? total : op(init, total)
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

function Base.reverse(l::List)
    isempty(l) && return l
    cs = chunks(l)
    isfull(cs[1]) ?
        typeof(l)(mapfoldl(reverse_fast, pushfirst, cs, init = empty(cs))) :
        typeof(l)(reverse!(collect(l)))
end

function PureFun.append(l1::L, l2::L) where {L <: List}
    isempty(l1) && return l2
    isempty(l2) && return l1
    ck = first(chunks(l2))
    isfull(ck) ? L(chunks(l1) ⧺ chunks(l2)) : L(vcat(collect(l1), collect(l2)))
end

function PureFun.halfish(xs::List)
    isempty(xs) && return xs, xs
    cs = chunks(xs)
    ck = popfirst(cs)
    if isempty(ck) && length(first(cs)) > 1
        c = first(cs)
        f = typeof(xs)(initialize(c[1], empty(xs)))
        r = typeof(xs)(popfirst(c))
        return (f,r,1)
    end
    f, r = halfish(cs)
    typeof(xs)(f), typeof(xs)(r)
end

# }}}

Base.IteratorSize(::Type{<:List}) = Base.HasLength()

end

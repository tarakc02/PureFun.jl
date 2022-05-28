module DenseLinkedList

using ..PureFun
using ..PureFun.Linked

struct Empty{K,T} <: PureFun.PFList{T}  where K end

struct Packed{K,T} <: PureFun.PFList{T}
    elems::NTuple{K,T}
    tail::Union{ Empty{K,T},Packed{K,T} }
end

struct Buffering{K,T} <: PureFun.PFList{T}
    buffer::Linked.NonEmpty{T}
    tail::Union{ Empty{K,T},Packed{K,T} }
    buffersize::Int
end

PackedList{K,T} = Union{ Empty{K,T},Buffering{K,T},Packed{K,T} } where {K,T}

maxelems(::PackedList{K,T}) where {K,T} = K

function Buffering(buffer, tail, bsize)
    T = eltype(buffer)
    K = maxelems(tail)
    Buffering{K,T}(buffer, tail, bsize)
end

# use buffer until the Kth element
hasroom(xs::Buffering) = xs.buffersize > 0

Base.empty(xs::Empty) = xs
Base.empty(xs::Buffering{K,T}) where {K,T} = Empty{K,T}()
Base.empty(xs::Packed{K,T}) where {K,T} = Empty{K,T}()
Base.isempty(xs::PackedList) = false
Base.isempty(xs::Empty) = true

function PureFun.cons(x, xs::PackedList{K,T}) where {K,T}
    buffer = cons(x, Linked.List{T}())
    # buffer can contain K-1 elements, we just added 1 element,
    # so remaining buffersize is K-2
    Buffering(buffer, xs, K-2)
end

# adding an element reduces the available buffer by 1 until it is empty
function PureFun.cons(x, xs::Buffering{K,T}) where {K,T}
    hasroom(xs) ? Buffering(cons(x,xs.buffer), xs.tail, xs.buffersize-1) : pack_buffer(x, xs)
end

function pack_buffer(x, xs::Buffering{K,T}) where {K,T}
    elems = NTuple{K,T}(cons(x, xs.buffer))
    Packed(elems, xs.tail)
end

PureFun.head(xs::Buffering) = head(xs.buffer)
PureFun.head(xs::Packed) = xs.elems[1]

# tail returns a buffer space to availability
function PureFun.tail(xs::Buffering)
    bt = tail(xs.buffer)
    isempty(bt) ? xs.tail : Buffering(bt, xs.tail, xs.buffersize+1)
end

function PureFun.tail(xs::Packed{K,T}) where {K,T}
    buf = tail(foldr(cons, xs.elems, init=Linked.List{T}()))
    Buffering(buf, xs.tail, 0)
end

function PackedList{K}(iter) where K
#    T = eltype(iter)
#    remain = rem(length(iter), K)
#    packs = Iterators.partition(iter[remain+1:end], K)
#    tups = collect(NTuple{K,T}(pack) for pack in packs)
#    packed = foldr(Packed, tups, init = PackedList{K,T}())
#    if remain > 0
#        buffer = Linked.List(iter[begin:remain])
#        return Buffering(buffer, packed, K-remain-1)
#    else
#        return packed
#    end
    foldl(push, reverse(iter); init=Empty{K, eltype(iter)}())
end

PackedList{K,T}() where {K,T} = Empty{K,T}()

Base.iterate(iter::Buffering) = iterate(iter, (iter.buffer, iter.tail, 1))
Base.iterate(iter::Packed{K,T}) where {K,T} = iterate(iter, (Linked.List{T}(), iter, 1))

function Base.iterate(iter::PackedList{K,T}, state) where {K,T}
    buf,packs,ind = state
    !isempty(buf) && return head(buf), (tail(buf),packs,ind)
    isempty(packs) && return nothing
    ind<=K && return packs.elems[ind], (buf,packs,ind+1)
    isempty(packs.tail) && return nothing
    pck = packs.tail
    return pck.elems[1], (buf,pck,2)
end

end

#@btime l = PureFun.Linked.List(1:19)
#@btime pl = PureFun.DenseLinkedList.PackedList{16}(1:19)
#
#@btime cons(0, $l)
##@btime NTuple{16,Int}(cons(0,$l))
#@btime cons(0, $pl)
#@btime head($l)
#@btime head($pl)
#
#function cons_repeatedly(init, iter)
#    out = init
#    for i in iter out = cons(i, out) end
#    return out
#end
#
#@btime cons_repeatedly(PureFun.DenseLinkedList.PackedList{16,Int}(), 1:19)
#@btime reverse(foldl(push, 1:19, init=PureFun.DenseLinkedList.PackedList{16,Int}()))
#@btime foldl(push, reverse(1:19), init=PureFun.DenseLinkedList.PackedList{16,Int}())
#@btime foldl(push, reverse(1:19), init=PureFun.Linked.List{Int}())


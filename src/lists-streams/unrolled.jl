module Unrolled

#using PureFun
using ...PureFun
using PureFun.Lists.Linked

# a fixed length vector {{{
#abstract type Fixed{N,T} <: PureFun.PFList{T} end

# normally we fill from the right to the left
# if `rev` then we fill from left to right
struct Fixed{N,T} <: PureFun.PFList{T}
    xs    :: NTuple{N,T}
    first :: UInt8
    last  :: UInt8
    rev   :: Bool
end

function Fixed(iter)
    N = length(iter)
    T = eltype(iter)
    Fixed{N,T}(NTuple{N,T}(iter), 0x01, UInt8(N), false)
end

normalorder(a::Fixed) = !a.rev
Base.reverse(a::Fixed{N,T}) where {N,T} = Fixed{N,T}(a.xs, a.last, a.first, !a.rev)
Base.length(a::Fixed) = convert(Int64, normalorder(a) ? a.last-a.first+0x01 : a.first-a.last+0x01)
Base.isempty(a::Fixed) = normalorder(a) ? a.first > a.last : a.first < a.last
Base.first(a::Fixed) = a.xs[a.first]
isfull(a::Fixed) = normalorder(a) ? a.first < 0x02 : a.first >= chunksize(a)
almostempty(a::Fixed) = normalorder(a) ? a.first >= chunksize(a) : a.first < 0x02

Base.getindex(a::Fixed, i::Integer) = a.xs[a.first+(UInt8(i))-0x01]

Base.@propagate_inbounds Base.iterate(iter::Fixed) = isempty(iter) ? nothing : (first(iter), decrement(iter))
Base.@propagate_inbounds function Base.iterate(iter::Fixed, state)
    r = iter.rev
    ((!r && state > iter.last) || (r && state < iter.last)) && return nothing
    return iter.xs[state], decrement(iter, state)
end

# when adding an element
function increment(a::Fixed)
    normalorder(a) ? a.first - 0x01 : a.first + 0x01
end

# when popping an element
function decrement(a::Fixed)
    normalorder(a) ? a.first + 0x01 : a.first - 0x01
end

function decrement(a::Fixed, cur)
    normalorder(a) ? cur + 0x01 : cur - 0x01
end

function PureFun.tail(a::Fixed{N,T}) where {N,T}
    Fixed{N,T}(a.xs, decrement(a), a.last, a.rev)
end

@inbounds function copyadd(x, f::Fixed{N,T}, ind) where {N,T}
    xs = f.xs
    new_xs = NTuple{N,T}(i == ind ? x : xs[i] for i in eachindex(xs))
    Fixed{N,T}(new_xs, ind, f.last, f.rev)
end

function PureFun.cons(x::T, xs::Fixed{N,T}) where {N,T}
    new_data = copyadd(x, xs, increment(xs))
end

function init(el::T, N::UInt8) where T
    Fixed(NTuple{convert(Int64, N),T}(el for _ in 1:N), N, N, false)
end

chunksize(x::Fixed{N,T}) where {N,T} = convert(UInt8, N)
# }}}

# list {{{
struct List{T,N,L} <: PureFun.PFList{T} where {N,L<:Linked.List{ Fixed{N, T}} }
    l::L
end

Empty{T,N} = List{ T,N,Linked.Empty{ Fixed{N,T}} } where {T,N}

# accessors:
list(list::List) = list.l
chunksize(::List{T,N,L}) where {T,N,L} = convert(UInt8, N)
Base.isempty(::Empty{T,N}) where {T, N} = true
Base.isempty(::List{T,N,L}) where {T, N, L<:Linked.NonEmpty} = false

List(e::Linked.List{ Fixed{N,T} }) where {T,N} = List{T,N,typeof(e)}(e)
List{T,N}() where {T,N} = List(Linked.Empty{ Fixed{N, T} }())
List{T}() where T = List{T,32}()

function PureFun.cons(x, xs::Empty{T,N}) where {T,N}
    List{T,N,Linked.NonEmpty{ Fixed{N,T} }}(cons(init(x, chunksize(xs)), xs.l))
end
function PureFun.cons(x, xs::List{T,N,L}) where {T,N,L}
    cs = chunksize(xs)
    block = first(xs.l)
    if !isfull(block)
        newdata = cons(x, block)
        return List{T,N,L}(cons(newdata, tail(xs.l)))
    end
    newdata = init(x, cs)
    return List{T,N,L}(cons(newdata, xs.l))
end

Base.first(l::List) = first(first(l.l))
PureFun.tail(l::List) = almostempty(first(l.l)) ? List(tail(l.l)) : List(cons(tail(first(l.l)), tail(l.l)))
# }}}

# construct from an iterable + iteration utils {{{
List{N}(iter) where N = foldr( cons, iter; init=List{eltype(iter), N}()  )
List(iter) = foldr( cons, iter; init=List{eltype(iter), 32}()  )

Base.iterate(iter::Empty) = nothing

Base.@propagate_inbounds function Base.iterate(iter::List)
    chunk = first(iter.l)
    nextval = iterate(chunk)
    isnothing(nextval) && return nothing
    return nextval[1], (iter.l, nextval[2])
end

Base.@propagate_inbounds function Base.iterate(iter::List, state)
    chunklist, curindex = state
    curchunk, nextchunks... = chunklist
    nextval = iterate(curchunk, curindex)
    while isnothing(nextval)
        isempty(nextchunks) && return nothing
        chunklist = nextchunks
        newchunk = first(chunklist)
        nextval = iterate(newchunk)
    end
    return nextval[1], (chunklist, nextval[2])
end

function Base.getindex(l::List{T}, i::Integer) where T
    lst = list(l)
    chunk = first(lst)
    while (length(chunk) < i)
        i-=length(chunk)
        lst = tail(lst)
        chunk = first(lst)
    end
    chunk[i]
end

Base.length(l::Empty) = 0
Base.length(l::List) = reduce(+, map(length, l.l))
Base.empty(l::Empty{T,N}) where {T,N} = l
Base.empty(l::List{T,N,L}) where {T,N,L} = List{T,N}()

Base.reverse(l::Empty) = l
function Base.reverse(l::List)
    _reverse(l, empty(list(l)))
end
function _reverse(l::List, accum)
    lst = list(l)
    while !isempty(lst)
        accum = cons(reverse(first(lst)), accum)
        lst = tail(lst)
    end
    T, N, L = eltype(l), convert(Int64, chunksize(l)), typeof(accum)
    return List{T,N,L}(accum)
end
# }}}

end
#tmpa = Fixed(1:128)
#tmpb = Linked.List(1:10_000)

using .Unrolled
tmp = Unrolled.List{128}(1:10_000)

minimum(x for x in tmp)
maximum(x for x in tmp)

function tf1(iter)
    x = iterate(iter)
    return iterate(iter, x[2])
end

function tf2(iter)
    f = Iterators.flatten(iter.l)
    x = iterate(f)
    return iterate(f, x[2])
end

@btime minimum(minimum(el for el in chunk) for chunk in $tmp.l)
@btime minimum(x for x in $tmp)
@btime minimum(x for x in Iterators.flatten($tmp.l))
@btime sum(x for x in Iterators.flatten($tmp.l))
@btime sum(x for x in $tmp)
#@btime minimum(x for x in $tmpx)

@btime reverse($tmpc)
@btime reverse($tmpb)
@btime reverse($tmpa)

@btime length($tmpa)
@btime length($tmpb)

collect(tmp)

@btime length(tmp)
@btime fastlength(tmp)

tmp2 = Linked.List([x for x in tmp])

@btime collect(tmp)
@btime minimum(x for x in tmp)
@btime collect(tmp2)

cons(99, n) |> length


@code_warntype iterate(tmpc, iterate(tmpc)[2])

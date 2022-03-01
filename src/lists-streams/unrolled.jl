module Unrolled

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
Base.reverse(a::Fixed) = Fixed(a.xs, a.last, a.first, !a.rev)
Base.length(a::Fixed) = convert(Int64, normalorder(a) ? a.last-a.first+0x01 : a.first-a.last+0x01)
Base.isempty(a::Fixed) = normalorder(a) ? a.first > a.last : a.first < a.last
Base.first(a::Fixed) = a.xs[a.first]
isfull(a::Fixed) = normalorder(a) ? a.first < 0x02 : a.first >= chunksize(a)
almostempty(a::Fixed) = normalorder(a) ? a.first >= chunksize(a) : a.first < 0x02

Base.getindex(a::Fixed, i::Integer) = a.xs[a.first+(UInt8(i))-0x01]

#function Base.iterate(a::Fixed)
#    out = normalorder(a) ? a.xs[a.first:a.last] : a.xs[a.last:-1:a.first]
#    iterate(out)
#end

Base.iterate(iter::Fixed) = isempty(iter) ? nothing : (first(iter), decrement(iter))
Base.iterate(iter::Fixed, state) = state < 1 || state > chunksize(iter) ? nothing : (iter.xs[state], decrement(iter, state))

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

function PureFun.tail(a::Fixed)
    Fixed(a.xs, decrement(a), a.last, a.rev)
end

function copyadd(x, f::Fixed{N,T}, ind) where {N,T}
    xs = f.xs
    new_xs = NTuple{N,T}(i == ind ? x : xs[i] for i in eachindex(xs))
    Fixed(new_xs, ind, f.last, f.rev)
end

function PureFun.cons(x::T, xs::Fixed{N,T}) where {N,T}
    new_data = copyadd(x, xs, increment(xs))
end

function init(el::T, N::UInt8) where T
    Fixed(NTuple{Int(N),T}(el for _ in 1:N), N, N, false)
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
#List{T,N}(e::Linked.List{ Fixed{N,T} }) where {T,N} = List{T,N,typeof(e)}(e)
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
function Base.iterate(iter::List{T}) where T
    l = list(iter)
    chunk = first(l)
    val, ind = iterate(chunk)
    return val, (l, ind)
end

function Base.iterate(iter::List{T}, state) where T
    list, ind = state
    nextval = iterate(first(list), ind)
    #_iter(nextval, list)
    if isnothing(nextval)
        nextup = tail(list)
        isempty(nextup) && return nothing
        val, i = iterate(first(nextup))
        return val, (nextup, i)
    end
    x, newstate = nextval
    return x, (list, newstate)
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
    rev(l, empty(list(l)))
end
function rev(l::List, accum)
    lst = list(l)
    while !isempty(lst)
        accum = cons(reverse(first(lst)), accum)
        lst = tail(lst)
    end
    T, N, L = eltype(l), convert(Int64, chunksize(l)), typeof(accum)
    return List{T,N,L}(accum)
end
# }}}

tmp = cons(9, init(5, UInt8(2)))
reverse(tmp)

tmp = List{7}(1:25)
rt = reverse(tmp)
fn = tail(tail(rt.l)) |> tail

for x in reverse(tmp) println(x) end
for x in tmp println(x) end
collect(tmp)


tmpx = rand(Int64, 250)
tmpa = Fixed(1:250)
tmpb = Linked.List(1:1000)
tmpc = List{250}(1:1000)

@btime $tmpa[149]
@btime $tmpb[10]
@btime $tmpc[140]

@btime minimum(x for x in $tmpa)
@btime minimum(x for x in $tmpb)
@btime minimum(x for x in $tmpc)
@btime minimum(x for x in $tmpx)

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

end



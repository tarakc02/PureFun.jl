module Catenable

using ..PureFun
using ..PureFun.Lazy: @lz, Susp

const Queue = PureFun.Bootstrapped.Queue

struct SuspList{T}
    s::Susp
end

struct Empty{T} <: PureFun.PFList{T} end
struct NonEmpty{T} <: PureFun.PFList{T}
    head::T
    tail::Queue{SuspList{T}}
end

List{T} = Union{Empty{T}, NonEmpty{T}} where T

suspend(l::NonEmpty{T}) where T = SuspList{T}(@lz l)
function force(suspension::SuspList{T}) where T 
    PureFun.Lazy.force(suspension.s)::NonEmpty{T}
end


Base.isempty(::Empty) = true
Base.isempty(::NonEmpty) = false
Base.empty(e::Empty) = e
Base.empty(xs::NonEmpty{T}) where T = Empty{T}()

PureFun.head(l::NonEmpty) = l.head
PureFun.append(xs::NonEmpty, ::Empty) = xs
PureFun.append(::Empty, ys::NonEmpty) = ys
PureFun.append(xs::NonEmpty, ys::NonEmpty) = link(xs, suspend(ys))

link(xs, ys) = NonEmpty(head(xs), snoc(xs.tail, ys))

singleton(x) = NonEmpty(x, Queue{ SuspList{typeof(x)} }())

PureFun.cons(x, xs::List) = singleton(x) ⧺ xs
PureFun.snoc(xs::List, x) = xs ⧺ singleton(x)

PureFun.tail(xs::List) = isempty(xs.tail) ? empty(xs) : link_all(xs.tail)

function link_all(q::Queue{ SuspList{T} }) where T
    t = force(head(q))
    q2 = tail(q)
    isempty(q2) ? t : link(t, SuspList{T}(@lz link_all(q2)))
end

"""
    Catenable.List{T}()
    Catenable.List(iter)

A `Catenable.List` supports the usual list operations, but unlike the
`Linked.List` you can append two catenable lists in constant time.

# Parameters
`T::Type` element type (inferred if creating from `iter`)

# Examples
```@jldoctest
julia> a = PureFun.Catenable.List(1:3);

julia> b = PureFun.Catenable.List(4:5);

julia> a ⧺ b
1
2
7
4
5
```
"""
List{T}() where T = Empty{T}()
function List(iter)
    peek = first(iter)
    init = Empty{typeof(peek)}()
    foldl(snoc, iter, init=init)
end

end

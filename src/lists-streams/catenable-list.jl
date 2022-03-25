module Catenable

using ...PureFun
using ...PureFun.Queues.Bootstrapped
#using ...PureFun.Queues.Bootstrapped: Queue
using ...PureFun.Lazy: @lz, Susp

struct SuspList{T}
    s::Susp
end

Cats{T} = Union{ Bootstrapped.Empty{SuspList{T}},Bootstrapped.NonEmpty{SuspList{T}} } where T

struct Empty{T} <: PureFun.PFList{T} end
struct NonEmpty{T} <: PureFun.PFList{T}
    head::T
    tail::Cats{T}
end

List{T} = Union{Empty{T}, NonEmpty{T}} where {T}
List{T}() where T = Empty{T}()

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

singleton(x) = NonEmpty(x, Bootstrapped.Empty{ SuspList{typeof(x)} }())

PureFun.cons(x, xs::List) = singleton(x) ⧺ xs
PureFun.snoc(xs::List, x) = xs ⧺ singleton(x)

PureFun.tail(xs::List) = isempty(xs.tail) ? empty(xs) : link_all(xs.tail)

function link_all(q)
    t = force(head(q))
    q2 = tail(q)
    isempty(q2) ? t : link(t, SuspList{eltype(t)}(@lz link_all(q2)))
end

function List(iter)
    peek = first(iter)
    init = Empty{typeof(peek)}()
    foldl(snoc, iter, init=init)
end

end


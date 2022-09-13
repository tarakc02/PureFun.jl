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
Base.empty(::List{T}) where T = Empty{T}()
Base.empty(::List, eltype) = Empty{eltype}()

PureFun.head(l::NonEmpty) = l.head
PureFun.append(xs::NonEmpty{T}, ::Empty{T}) where T = xs
PureFun.append(::Empty{T}, ys::NonEmpty{T}) where T = ys
PureFun.append(xs::NonEmpty, ys::NonEmpty) = link(xs, suspend(ys))

link(xs, ys) = NonEmpty(head(xs), snoc(xs.tail, ys))

singleton(x, T) = NonEmpty(convert(T, x), Queue{ SuspList{T} }())

PureFun.cons(x, xs::List) = singleton(x, eltype(xs)) ⧺ xs

"""
    snoc(xs::Catenable.List, x)

Return the `Catenable.List` that results from adding an element to the rear of
`xs`. "`snoc` is [`cons`](@ref) from the right."
"""
PureFun.snoc(xs::List, x) = xs ⧺ singleton(x, eltype(xs))
PureFun.push(xs::List, x) = snoc(xs, x)

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
`Linked.List` you can append two catenable lists in constant time. These lists
are presented in section 10.2.1 of the book, as an example of data-structural
bootstrapping. In addition to list functions, catenable lists also support
`snoc`. Catenable lists work by maintaining the `head` element plus a queue of
catenable lists. Each element of this queue is suspended. `head` takes constant
time, while `cons`, `tail`, `snoc`, and `⧺` require amortized constant time.

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

PureFun.container_type(::Type{<:List{T}}) where T = List{T}

end


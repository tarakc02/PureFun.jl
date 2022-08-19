# note: all containers are expected to have implemented `Base.isempty`

export cons, pushfirst, snoc, push,
       append, ⧺,
       head, tail, rest,
       setindex,
       delete_min, delete_max,
       delete

import StaticArrays.pushfirst, StaticArrays.push
import Base.setindex

"""
    PFList{T}

Supertype for purely functional lists with elements of type `T`.

A `PFList` implements `cons` (equivalent to `pushfirst`), `head`, `tail`,
`getindex`, `setindex`, `append` and `reverse`.

See also [`PureFun.Linked.List`](@ref), [`PureFun.RandomAccess.List`](@ref),
and [`PureFun.Catenable.List`](@ref)
"""
abstract type PFList{T} end

"""
    PFQueue{T}

Supertype for purely functional FIFO queues with elements of type `T`.

A `PFQueue` implements `snoc` (equivalent to `push`), `head`, and `tail`

See also [`PureFun.Batched.Queue`](@ref), [`PureFun.Bootstrapped.Queue`](@ref),
and [`PureFun.RealTime.Queue`](@ref)
"""
abstract type PFQueue{T} end

"""
    PFHeap{T, O<:Base.Order.Ordering}

Supertype for purely functional heaps (aka priority queues) with elements of
type `T` and ordering `O`. These datastructures give fast access to the minimum
element, where comparisons are based on the supplied ordering.

A `PFHeap` implements `push`, `minimum`, `delete_min`, and `merge`.

See also [`PureFun.Pairing.Heap`](@ref), [`PureFun.SkewHeap.Heap`](@ref), and
[`PureFun.FastMerging.Heap`](@ref)
"""
abstract type PFHeap{T,O<:Base.Order.Ordering} end

abstract type PFDict{K, V} <: AbstractDict{K, V} end
abstract type PFStream{T} end
abstract type PFSet{T} <: AbstractSet{T} end

# pflists {{{
"""
    cons(x, xs::PFList)
    pushfirst(xs::PFList, x)

Return the `PFList` that results from adding `x` to the front of `xs`.
"""
function cons end

"""
    cons(x, xs::PFList)
    pushfirst(xs::PFList, x)

Return the `PFList` that results from adding `x` to the front of `xs`.
"""
pushfirst(xs::PFList, x) = cons(x, xs)

"""
    head(xs)

Return the first element of a `PFList` or `PFQueue`. See also [`tail`](@ref)
"""
function head end

"""
    tail(xs)

Return the collection `xs` without its first element (without modifying `xs`).
"""
function tail end
Base.tail(xs::PFList) = tail(xs)

"""
    append(xs, ys)
    xs ⧺ ys

Concatenate two `PFLists`.

```@jldoctest
julia> l1 = PureFun.Linked.List(1:3);

julia> l2 = PureFun.Linked.List(4:6);

julia> l1 ⧺ l2
1
2
3
4
5
6

```
"""
function append end
const ⧺ = append

Base.reverse(l::PFList) = foldl(pushfirst, l, init=empty(l))
append(l1::PFList, l2::PFList) = foldr(cons, l1, init=l2)

function Base.setindex(l::PFList, newval, ind)
    new = empty(l)
    cur = l
    i = ind
    while i > 1 && !isempty(cur)
        i -= 1
        new = cons(head(cur), new)
        cur = tail(cur)
    end
    i > 1 && throw(BoundsError(l, ind))
    return reverse(cons(newval, new)) ⧺ tail(cur)
end

# }}}

# PFQueue {{{
"""
    snoc(xs::PFQueue, x)
    push(xs::PFQueue, x)

Return the `PFQueue` that results from adding an element to the rear of `xs`.
"`snoc` is [`cons`](@ref) from the right."
"""
function snoc end

"""
    push(xs::PFQueue, x)

Equivalent to [`snoc`](@ref)
"""
push(xs::PFQueue, x) = snoc(xs, x)

"""
    push(xs::PFHeap, x)

Return the `PFHeap` that results from adding add `x` to the collection.
"""
push(xs::PFHeap, x) = throw(MethodError(push, (xs, x)))

Base.first(xs::PFQueue) = head(xs)
Base.rest(xs::PFQueue) = tail(xs)
Base.rest(::PFQueue, itr_state) = tail(itr_state)

function Base.length(xs::PFQueue)
    l = 0
    while !isempty(xs)
        xs = tail(xs)
        l += 1
    end
    l
end

# }}}

# PFHeap {{{
"""
    delete_min(xs::PFHeap)

return a new heap that is the result of deleting the minimum element from `xs`,
according to the ordering of `xs`.
"""
function delete_min end
function delete_max end
function delete end

Base.iterate(iter::PFHeap) = isempty(iter) ? nothing : (minimum(iter), iter)
function Base.iterate(::PFHeap, state)
    nxt = delete_min(state)
    isempty(nxt) && return nothing
    return minimum(nxt), nxt
end

Base.first(xs::PFHeap) = minimum(xs)
Base.eltype(::Type{<:PFHeap{T}}) where T = T
Base.rest(xs::PFHeap) = delete_min(xs)
Base.rest(::PFHeap, state) = delete_min(state)

# }}}

Base.first(xs::PFStream) = head(xs)

Base.eltype(::Type{<:PFSet{T}}) where T = T
Base.union(s::PFSet, iter) = foldl(push, iter, init = s)
Base.union(s::PFSet, sets...) = reduce(union, sets, init=s)

function Base.intersect(s::PFSet, iter)
    out = empty(s)
    for i in iter
        if member(s, i) out = push(out, i) end
    end
    return out
end
Base.intersect(s::PFSet, sets...) = reduce(sets, intersect, init=s)


# implements `head` and `tail`
const PFListy{T} = Union{PFList{T}, PFQueue{T}, PFStream{T}} where T

function Base.show(io::IO, ::MIME"text/plain", s::PFListy)
    cur = s
    n = 7
    while n > 0 && !isempty(cur)
        print(io, first(cur))
        cur = tail(cur)
        !isempty(cur) && n > 1 && print(io, "\n")
        n -= 1
    end
    n <= 0 && print(io, "\n...")
end

# compact (1-line) version of show
Base.show(io::IO, s::PFListy) = print(io, "$(typeof(s))", " length: $(length(s))")

function Base.show(io::IO, ::MIME"text/plain", s::PFHeap)
    cur = s
    n = 7
    while n > 0 && !isempty(cur)
        print(io, minimum(cur))
        cur = delete_min(cur)
        !isempty(cur) && n > 1 && print(io, "\n")
        n -= 1
    end
    n <= 0 && print(io, "\n...")
end

function Base.getindex(l::PFListy, ind)
    cur = l
    i = ind
    while i > 1 && !isempty(cur)
        i -= 1
        cur = tail(cur)
    end
    i > 1 && throw(BoundsError(l, ind))
    return head(cur)
end


# iteration/abstractarray stuff {{{
function Base.iterate(r::Iterators.Reverse{<:PFList{T}}) where T
    itr = r.itr
    rev = foldl(pushfirst, itr, init = Linked.List{T}())
    return head(rev), rev
end

function Base.iterate(::Iterators.Reverse{<:PFList{T}}, state) where T
    st = tail(state)
    isempty(st) && return nothing
    return head(st), st
end

Base.first(xs::PFListy) = head(xs)
Base.rest(l::PFListy) = tail(l)
Base.rest(::PFListy, itr_state) = tail(itr_state)

Base.iterate(iter::PFListy) = isempty(iter) ? nothing : (head(iter), iter)
function Base.iterate(::PFListy, state)
    nxt = tail(state)
    isempty(nxt) && return nothing
    return head(nxt), nxt
end

Base.IndexStyle(::Type{<:PFListy}) = IndexLinear()
Base.IteratorSize(::Type{<:PFListy}) = Base.SizeUnknown()
Base.size(iter::PFList) = (length(iter),)
Base.eltype(::Type{<:PFListy{T}}) where T = T
Base.firstindex(l::PFListy) = 1

function Base.length(iter::PFList)
    len = 0
    while !isempty(iter)
        len += 1
        iter = tail(iter)
    end
    return len
end
# }}}

Base.filter(f, l::PFList) = foldr(cons, Iterators.filter(f, l), init=empty(l))

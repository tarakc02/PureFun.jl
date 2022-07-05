# note: all containers are expected to have implemented `Base.isempty`

export cons, pushfirst, snoc, push,
       append, ⧺,
       head, tail, rest,
       setindex,
       delete_min, delete_max,
       delete

import StaticArrays.pushfirst, StaticArrays.push
import Base.setindex

abstract type PFList{T} end
abstract type PFSet{T} <: AbstractSet{T} end
abstract type PFStream{T} end
abstract type PFDict{K, V} <: AbstractDict{K, V} end
abstract type PFQueue{T} end
abstract type PFHeap{T,O<:Base.Order.Ordering} end

# pflists {{{
"""
    cons(x, xs::PFList)
    pushfirst(xs::PFList, x)

Return the `PFList` that results from adding `x` to the front of `xs`.
"""
function cons end
pushfirst(xs::PFList, x) = cons(x, xs)

function head end
function tail end
Base.tail(xs::PFList) = tail(xs)
function append end
const ⧺ = append

# iteration/abstractarray stuff {{{
Base.first(xs::PFList) = head(xs)
Base.rest(l::PFList) = tail(l)
Base.rest(l::PFList, itr_state) = tail(itr_state)

Base.iterate(iter::PFList) = isempty(iter) ? nothing : (head(iter), iter)
function Base.iterate(iter::PFList, state)
    nxt = tail(state)
    isempty(nxt) && return nothing
    return head(nxt), nxt
end

function Base.iterate(r::Iterators.Reverse{<:PFList{T}}) where T
    itr = r.itr
    rev = foldl(pushfirst, itr, init = Linked.List{T}())
    return head(rev), rev
end

function Base.iterate(r::Iterators.Reverse{<:PFList{T}}, state) where T
    st = tail(state)
    isempty(st) && return nothing
    return head(st), st
end

Base.IndexStyle(::Type{<:PFList}) = IndexLinear()
Base.IteratorSize(::Type{<:PFList}) = Base.SizeUnknown()
Base.size(iter::PFList) = (length(iter),)
Base.eltype(::Type{<:PFList{T}}) where T = T
Base.firstindex(l::PFList) = 1

function Base.length(iter::PFList)
    len = 0
    while !isempty(iter)
        len += 1
        iter = tail(iter)
    end
    return len
end
# }}}

# possibly slow but useful {{{
Base.reverse(l::PFList) = foldl(pushfirst, l, init=empty(l))
append(l1::PFList, l2::PFList) = foldr(cons, l1, init=l2)

function Base.getindex(l::PFList, ind)
    cur = l
    i = ind
    while i > 1 && !isempty(cur)
        i -= 1
        cur = tail(cur)
    end
    i > 1 && throw(BoundsError(l, ind))
    return head(cur)
end

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

# }}}

# PFQueue {{{
function snoc end
push(xs::PFQueue, x) = snoc(xs, x)

Base.first(xs::PFQueue) = head(xs)
Base.rest(xs::PFQueue) = tail(xs)
Base.rest(l::PFQueue, itr_state) = tail(itr_state)

function Base.length(xs::PFQueue)
    l = 0
    while !isempty(xs)
        xs = tail(xs)
        l += 1
    end
    l
end

Base.iterate(iter::PFQueue) = isempty(iter) ? nothing : (head(iter), iter)
function Base.iterate(iter::PFQueue, state)
    nxt = tail(state)
    isempty(nxt) && return nothing
    return head(nxt), nxt
end
# }}}

# PFHeap {{{
function delete_min end
function delete_max end
function delete end

Base.iterate(iter::PFHeap) = isempty(iter) ? nothing : (minimum(iter), iter)
function Base.iterate(iter::PFHeap, state)
    nxt = delete_min(state)
    isempty(nxt) && return nothing
    return minimum(nxt), nxt
end

Base.first(xs::PFHeap) = minimum(xs)
Base.eltype(::Type{<:PFHeap{T}}) where T = T
Base.rest(xs::PFHeap) = delete_min(xs)
Base.rest(xs::PFHeap, state) = delete_min(state)

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


#struct Ordered{T, O <: Base.Order.Ordering}
#    elem::T
#    order::O
#end
#
#ordering(x::Ordered) = x.order
#ordering(x::Ordered{T, O}, y::Ordered{T, O}) where {T, O} = ordering(x)
#
#lt(x, y) = Base.Order.lt(ordering(x, y), x, y)
#leq(x, y) = !Base.Order.lt(ordering(x, y), y, x)
#eq(x, y) = x == y

function Base.show(io::IO, ::MIME"text/plain", s::PFList)
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
Base.show(io::IO, s::PFList) = print(io, "$(typeof(s))", " length: $(length(s))")

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


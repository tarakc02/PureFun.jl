# note: all containers are expected to have implemented `Base.isempty`

# `push` is provided as an analogue to `Base.push!`, and `append` as `append!`
export push, cons, snoc, append, ⧺, head, tail,
       delete_min, delete_max, insert, delete

# anything that implements `PureFun.cons`, `PureFun.head`, and `PureFun.tail` can
# register as an implementation of a stack/linked list
abstract type PFList{T} end
# a PFSet must implement `PureFun.insert` and `Base.in`
abstract type PFSet{T} <: AbstractSet{T} end
abstract type PFStream{T} end
# a PFDict should implement `PureFun.setindex` and `Base.getindex`
abstract type PFDict{K, V} <: AbstractDict{K, V} end

#=

A `PFQueue` must implement `PureFun.snoc`, `PureFun.head`, and `PureFun.tail`

=#
abstract type PFQueue{T} end
abstract type PFHeap{T} end

# shorthand for data structures that implement `PureFun.head` and `PureFun.tail`
const Listy{T} = Union{PFList{T}, PFQueue{T}, PFStream{T}, PFHeap{T}} where T

"""
    cons(x, xs::PFList)
    push(xs::PFList, x)

Return the `PFList` that results from adding `x` to the front of `xs`.
"""
function cons end
push(xs::PFList, x) = cons(x, xs)

function head end
function tail end
Base.tail(xs::Listy) = tail(xs)
function append end
const ⧺ = append

function snoc end
function setindex end
Base.setindex(xs::PFList, i, y) = setindex(xs, i, y)

# operations for PFHeap
#function find_min end
function delete_min end
function delete_max end
function delete end
#push(xs::PFQueue, x) = snoc(xs, x)
#push(xs::PFSet, x) = insert(xs, x)
#push(xs::PFHeap, x) = insert(xs, x)

Base.first(xs::PFList) = head(xs)
Base.first(xs::PFStream) = head(xs)
Base.first(xs::PFHeap) = minimum(xs)
Base.first(xs::PFQueue) = head(xs)

Base.rest(l::Listy) = tail(l)
Base.rest(l::Listy, itr_state) = tail(itr_state)

# fallback implementations of methods for list-like containers {{{
Base.iterate(iter::Listy) = isempty(iter) ? nothing : (first(iter), iter)
function Base.iterate(iter::Listy, state)
    nxt = tail(state)
    isempty(nxt) && return nothing
    return first(nxt), nxt
end

Base.IndexStyle(::Listy) = IndexLinear()
Base.IteratorSize(::Listy) = Base.SizeUnknown()
Base.size(iter::Listy) = (length(iter),)
Base.eltype(::Type{<:Listy{T}}) where T = T
Base.firstindex(l::Listy) = 1

function Base.length(iter::Listy)
    len = 0
    while !isempty(iter)
        len += 1
        iter = tail(iter)
    end
    return len
end

Base.reverse(l::PFList) = foldl(push, l, init=empty(l))
append(l1::PFList, l2::PFList) = foldl(push, reverse(l1), init=l2)

function Base.getindex(l::Listy, ind)
    cur = l
    i = ind
    while i > 1 && !isempty(cur)
        i -= 1
        cur = tail(cur)
    end
    i > 1 && throw(BoundsError(l, ind))
    return head(cur)
end

function PureFun.setindex(l::PFList, ind, newval)
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

function insert end

Base.union(s::PFSet, iter) = foldl(insert, iter, init = s)
Base.union(s::PFSet, sets...) = reduce(union, sets, init=s)

function Base.intersect(s::PFSet, iter)
    out = empty(s)
    for i in iter
        if member(s, i) out = insert(out, i) end
    end
    return out
end
Base.intersect(s::PFSet, sets...) = reduce(sets, intersect, init=s)

Base.eltype(::PFSet{T}) where T = T


struct Ordered{T, O <: Base.Order.Ordering}
    elem::T
    order::O
end

ordering(x::Ordered) = x.order
ordering(x) = Base.Order.Forward
ordering(x::Ordered{T, O}, y::Ordered{T, O}) where {T, O} = ordering(x)
ordering(x::Ordered{T}, y::T) where T = ordering(x)
ordering(x::T, y::Ordered{T}) where T = ordering(y)
ordering(x::T, y::T) where T = ordering(x)

lt(x, y) = Base.Order.lt(ordering(x, y), x, y)
leq(x, y) = !Base.Order.lt(ordering(x, y), y, x)
eq(x, y) = x == y

function Base.show(::IO, ::MIME"text/plain", s::Listy)
    cur = s
    n = 7
    while n > 0 && !isempty(cur)
        println(first(cur))
        cur = tail(cur)
        n -= 1
    end
    n <= 0 && println("...")
end



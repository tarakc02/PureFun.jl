#=

where they exist, trying to extend the appropriate functions in Base (or
DataStructures?). open question is what to do about mutating ops (the ones that
end in `!`).

- `push` returns a new collection instead of mutating an existing one, this
  matches as much as possible the semantics of `push!` which also returns the
  updated collection

- `pop`: does this make sense in a functional setting? i could return a tuple
  of (value, newcollection) but that seems hacky. don't implement

=#

# note: all containers are expected to have implemented `Base.isempty`

# `push` is provided as an analogue to `Base.push!`, and `append` as `append!`
export push, cons, snoc, append, ⧺, tail


# anything that implements `PureFun.cons`, `Base.first`, and `PureFun.tail` can register as an
# implementation of a stack/linked list
abstract type PFList{T} <: AbstractArray{T, 1} end
# a PFSet must implement `insert` and `in`
abstract type PFSet{T} <: AbstractSet{T} end
abstract type PFStream{T} end
#Base.eltype(::PFStream{T}) where T = T
# a PFDict should implement `PureFun.setindex` and `Base.getindex`
abstract type PFDict{K, V} <: AbstractDict{K, V} end
#Base.eltype(::PFDict{K, V}) where {K, V} = Pair{K, V}
#=

A `PFQueue` must implement `PureFun.push` and `Base.first`. Sticking with the
conventions in DataStructures.jl, though it means `push` has different meanings
for different data types

=#
abstract type PFQueue{T} end
abstract type PFHeap{T} end

# shorthand for data structures that implement `Base.first` and `PureFun.tail`
const Listy{T} = Union{PFList{T}, PFQueue{T}, PFStream{T}, PFHeap{T}} where T

function cons end
function tail end
function append end

function snoc end
function setindex end

# operations for PFHeap
function merge end
function find_min end
function delete_min end
push(xs::PFList, x) = cons(x, xs)
push(xs::PFQueue, x) = snoc(xs, x)
push(xs::PFSet, x) = insert(xs, x)
push(xs::PFHeap, x) = insert(xs, x)

const ⧺ = append
#function ⧺ end
#function head end
#function tail end

Base.iterate(iter::Listy) = isempty(iter) ? nothing : (first(iter), tail(iter))
Base.iterate(iter::Listy, state) = isempty(state) ? nothing : (first(state), tail(state))
Base.IndexStyle(::Listy) = IndexLinear()
Base.length(iter::Listy) = isempty(iter) ? 0 : 1 + length(tail(iter))
Base.size(iter::Listy) = (length(iter),)
Base.eltype(::Listy{T}) where T = T
Base.firstindex(l::Listy) = 1

function Base.getindex(l::Listy, i)
    isempty(l) && BoundsError(l, i)
    i == 1 && return first(l)
    getindex(tail(l), i - 1)
end


function insert end
#function member end

Base.union(s::PFSet, iter) = foldl(push, iter, init = s)
function Base.union(s::PFSet, sets...)
    out = s
    for s₀ in sets
        out = union(s, s₀)
    end
    return out
end

function Base.intersect(s::PFSet, iter)
    out = empty(s)
    for i in iter
        if member(s, i) out = insert(out, i) end
    end
    return out
end

function Base.intersect(s::PFSet, sets...)
    out = s
    for s₀ in sets
        out = intersect(out, s₀)
    end
    return out
end

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



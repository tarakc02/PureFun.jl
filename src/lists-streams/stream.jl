#=
# Streams

In this module we take a different approach to the [`List`](@ref) API.
We systematically [suspend](docs/laziness) each element, only forcing it when
necessary.
=#
module Lazy

export @cons
using ..PureFun
include("laziness.jl")

# ## Type definitions
struct Empty{T} end

struct NonEmpty{T}
    head::Susp
    tail::Susp
end

Stream{T} = Union{ NonEmpty{T}, Empty{T} }

"""
    @cons T headexpr tailexpr

this macro makes it more convenient to construct a stream
"""
macro cons(T, headexpr, tailexpr)
    h = quote
        () -> $(esc(headexpr))
    end
    t = quote
        () -> $(esc(tailexpr))
    end
    head = :(Susp($h))
    tail = :(Susp($t))
    return :(NonEmpty{$(esc(T))}($head, $tail))
end

Base.empty(::Stream{T}) where {T} = Empty{T}()
(PureFun.head(s::NonEmpty{T})::T) where {T} = force(s.head)::T
(PureFun.tail(s::NonEmpty{T})::Stream{T}) where {T} = force(s.tail)::Stream{T}

PureFun.take(k::Int64, s::Empty) = s
function PureFun.take(k::Int64, s::NonEmpty{T}) where {T}
    k <= 0 ? empty(s) : @cons(T, head(s), take(k-1, tail(s)) )
end

Base.getindex(s::Empty, i::Integer) = throw( BoundsError(s, i))
Base.getindex(s::NonEmpty, i::Integer) = i > 1 ? getindex(tail(s), i-1) : head(s)
PureFun.is_empty(s::NonEmpty) = false
PureFun.is_empty(s::Empty) = true

Base.iterate(::Empty) = nothing
Base.iterate(::Stream, ::Empty) = nothing
Base.iterate(iter::Stream) = head(iter), tail(iter)
Base.iterate(::Stream, state::Stream) = head(state), tail(state)
Base.eltype(::Stream{T}) where {T} = T

function Base.show(::IO, ::MIME"text/plain", s::Empty)
    print("an empty stream of type $(typeof(s))")
end

function Base.show(::IO, ::MIME"text/plain", s::NonEmpty)
    cur = s
    n = 7
    while n > 0 && !is_empty(cur)
        println(head(cur))
        cur = tail(cur)
        n -= 1
    end
    n <= 0 && println("...")
end


function Stream(iter)
    T = eltype(iter)
    el = iterate(iter)
    isnothing(el) && return Empty{T}()
    init, state = el
    return @cons(T, init, Stream(T, iter, state))
end

function Stream(T, iter, state)
    el = iterate(iter, state)
    isnothing(el) && return Empty{T}()
    next, state = el
    return @cons(T, next, Stream(T, iter, state))
end

Stream{T}() where T = Empty{T}()

randstream() = randstream(Float16)
function randstream(T)
    @cons(T, rand(T), randstream(T))
end


#=
#
## Functionals (map, accumulate)

We can implement `map` and `accumulate`, but not `length`, `reduce`, or
`foldl`/`foldr`. The latter assume that a list has finite length, and we don't
want to constrain implementations in that way.

In each case, we do some setup

=#

_map(T, f, s::Empty) = Empty{T}()
function _map(T, f, s::NonEmpty)
    @cons T f(head(s)) _map(T, f, tail(s))
end

function Base.map(f, s::NonEmpty)
    init = f(head(s))
    T = typeof(init)
    @cons T init _map(T, f, tail(s))
end

_accumulate(T, f, xs::Empty, init) = Empty{T}()
function _accumulate(T, f, xs::NonEmpty, init)
    nextval = @lz f(init, head(xs))
    @cons T force(nextval) _accumulate(T, f, tail(xs), force(nextval))
end

function Base.accumulate(f, xs::NonEmpty, init)
    initval = f(init, head(xs))
    T = typeof(initval)
    @cons T initval _accumulate(T, f, tail(xs), initval)
end

function Base.filter(p, xs::NonEmpty{T}) where {T}
    pred = p(head(xs))
    pred ? @cons(T, head(xs), filter(p, tail(xs))) : filter(p, tail(xs))
end

end

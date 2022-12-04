#=
# Streams

In this module we take a different approach to the [`List`](@ref) API.
We systematically [suspend](docs/laziness) each element, only forcing it when
necessary.
=#
module Lazy

export @stream
using ..PureFun
include("laziness.jl")

# ## Type definitions
struct Empty{T} <: PureFun.PFStream{T} end

struct NonEmpty{T} <: PureFun.PFStream{T}
    head::Susp
    tail::Susp
end

@doc raw"""
    Stream{T} <: PureFun.PFStream{T}

Stream with elements of type `T`. Every cell in a stream is systematically
suspended, and only evaluated when the value in that cell is required.
Furthermore, the value is cached the first time a cell is evaluated, so that
subsequent accesses are cheap. Introduced in $\S{4.2}$
"""
Stream{T} = Union{ NonEmpty{T}, Empty{T} }

"""
    @stream T headexpr tailexpr

this macro makes it more convenient to construct a stream
"""
macro stream(T, headexpr, tailexpr)
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
Base.empty(::Stream, eltype) = Empty{eltype}()
(PureFun.head(s::NonEmpty{T})::T) where {T} = force(s.head)::T
(PureFun.tail(s::NonEmpty{T})::Stream{T}) where {T} = force(s.tail)::Stream{T}

Base.IteratorSize(::Type{<:Stream}) = Base.SizeUnknown()
Base.isempty(s::NonEmpty) = false
Base.isempty(s::Empty) = true

function Stream(iter)
    T = Base.@default_eltype(iter)
    el = iterate(iter)
    isnothing(el) && return Empty{T}()
    #init, state = el
    return @stream(T, el[1], Stream(T, iter, el[2]))
end

function Stream(T, iter, state)
    el = iterate(iter, state)
    isnothing(el) && return Empty{T}()
    next, state = el
    return @stream(T, next, Stream(T, iter, state))
end

Stream{T}() where T = Empty{T}()

function PureFun.append(s1::Stream{T}, s2::Stream{T}) where T
    isempty(s1) ? s2 : @stream(eltype(s1), head(s1), tail(s1) ⧺ s2)
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
    @stream T f(head(s)) _map(T, f, tail(s))
end

function Base.map(f, s::NonEmpty)
    init = f(head(s))
    T = typeof(init)
    @stream T init _map(T, f, tail(s))
end

_accumulate(T, f, xs::Empty, init) = Empty{T}()
function _accumulate(T, f, xs::NonEmpty, init)
    nextval = @lz f(init, head(xs))
    @stream T force(nextval) _accumulate(T, f, tail(xs), force(nextval))
end

function Base.accumulate(f, xs::NonEmpty, init)
    initval = f(init, head(xs))
    T = typeof(initval)
    @stream T initval _accumulate(T, f, tail(xs), initval)
end

function Base.filter(p, xs::NonEmpty{T}) where {T}
    pred = p(head(xs))
    pred ? @stream(T, head(xs), filter(p, tail(xs))) : filter(p, tail(xs))
end

end

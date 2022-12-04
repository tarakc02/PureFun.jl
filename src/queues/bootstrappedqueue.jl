module Bootstrapped

using ..PureFun
using ..PureFun.Linked
using ..PureFun.Lazy: @lz, Susp

function snoclist(l::Linked.List{T}, x::T) where T
    isempty(l) ? cons(x, l)::Linked.NonEmpty{T} : cons(head(l), snoclist(tail(l), x))::Linked.NonEmpty{T}
end

struct ReverseLater{T}
    s::Susp
end
ReverseLater(l::Linked.NonEmpty{T}) where T = ReverseLater{T}(@lz reverse(l))
function force(reversal::ReverseLater{T}) where T 
    PureFun.Lazy.force(reversal.s)::Linked.NonEmpty{T}
end

struct Empty{T} <: PureFun.PFQueue{T} end
struct NonEmpty{T} <: PureFun.PFQueue{T}
    lenfm::Int
    f::Linked.NonEmpty{T}
    m::Union{ Empty{ReverseLater{T}},NonEmpty{ReverseLater{T}} }
    lenr::Int
    r::Linked.List{T}
end

Queue{T} = Union{ Empty{T},NonEmpty{T} } where T

Base.empty(::Queue{T}) where {T} = Empty{T}()
Base.isempty(::Empty) = true
Base.isempty(::NonEmpty) = false

PureFun.head(q::NonEmpty) = head(q.f)

issmall(q::NonEmpty) = isempty(q.r) && q.lenfm<4
smallish(q::NonEmpty) = q.lenfm+q.lenr<4 && isempty(q.m)

function PureFun.snoc(q::Empty{T}, x) where T
    NonEmpty(1, cons(x, Linked.List{T}()),
             Empty{ReverseLater{T}}(),
             0, Linked.List{T}())
end

function PureFun.snoc(q::NonEmpty{T}, x) where T
    if issmall(q)
        NonEmpty(q.lenfm+1,
                 snoclist(q.f,x),
                 q.m::Empty{ReverseLater{T}},
                 0, q.r::Linked.Empty{T})
    elseif smallish(q)
        NonEmpty(q.lenfm+q.lenr,
                 foldl(snoclist, reverse(q.r), init=q.f)::Linked.NonEmpty{T},
                 q.m, 0, empty(q.r))
    else
        checkq(q.lenfm, q.f, q.m, q.lenr+1, cons(x, q.r))
    end
end

PureFun.tail(q::NonEmpty) = checkq(q.lenfm-1, tail(q.f), q.m, q.lenr, q.r)

function checkq(lenfm, f, m, lenr, r)
    if lenr<=lenfm
        checkf(lenfm, f, m, lenr, r)
    else 
        checkf(lenfm+lenr, f, snoc(m, ReverseLater(r)), 0, empty(r))
    end
end

checkf(lenfm, f::Linked.Empty{T}, m::Empty, lenr, r) where T = Empty{T}()
function checkf(lenfm, f::Linked.Empty{T}, m::NonEmpty, lenr, r) where T
    NonEmpty(lenfm, force(head(m)), tail(m), lenr, r)::NonEmpty{T}
end

function checkf(lenfm, f::Linked.List{T}, m, lenr, r) where T
    NonEmpty(lenfm, f, m, lenr, r)::NonEmpty{T}
end

@doc raw"""

    Bootstrapped.Queue{T}()
    Bootstrapped.Queue(iter)

`first` takes $\mathcal{O}(1)$ time, while both `push` and `popfirst` take
$\mathcal{O}(\log^{*}{n})$ amortized time, where $\log^{*}$ is the [iterated
logarithm](https://en.wikipedia.org/wiki/Iterated_logarithm), which is
"constant in practice." The amortized bounds extend to settings that require
persistence, this is achieved via disciplined use of [*lazy
evaluation*](https://en.wikipedia.org/wiki/Lazy_evaluation) along with
[memoization](https://en.wikipedia.org/wiki/Memoization)

# Examples

```jldoctest
julia> using PureFun, PureFun.Bootstrapped
julia> q = Bootstrapped.Queue(1:3)
3-element PureFun.Bootstrapped.NonEmpty{Int64}
1
2
3

julia> push(q, 4)
4-element PureFun.Bootstrapped.NonEmpty{Int64}
1
2
3
4

julia> popfirst(q)
2-element PureFun.Bootstrapped.NonEmpty{Int64}
2
3

```
"""
Queue{T}() where T = Empty{T}()
function Queue(iter)
    T = eltype(iter)
    lenfm = length(iter)
    f = Linked.List(iter)
    NonEmpty(lenfm, f, Empty{ReverseLater{T}}(), 0, empty(f))
end

Base.IteratorSize(::Queue) = Base.HasLength()
Base.length(q::Empty) = 0
Base.length(q::NonEmpty) = q.lenfm + q.lenr

end


module Bootstrapped

using ...PureFun
using ...PureFun.Lists.Linked
using ...PureFun.Lazy: @lz, Susp

struct ReverseLater{T}
    s::Susp
end
ReverseLater(l::Linked.NonEmpty{T}) where T = ReverseLater{T}(@lz reverse(l))
function force(reversal::ReverseLater{T}) where T 
    PureFun.Lazy.force(reversal.s)::Linked.NonEmpty{T}
end

abstract type Queue{T} <: PureFun.PFQueue{T} end
struct Empty{T} <: Queue{T} end
struct NonEmpty{T, M, R} <: Queue{T} where {M <: Queue{ ReverseLater{T} }, R <: Linked.List{T}}
    lenfm::Int
    f::Linked.NonEmpty{T}
    m::M
    lenr::Int
    r::R
end

function NonEmpty(lenfm, f::Linked.NonEmpty{T}, m::M, lenr, r::R) where {T,M,R}
    NonEmpty{T,M,R}(lenfm, f, m, lenr, r)
end

Base.empty(::Queue{T}) where {T} = Empty{T}()
Base.isempty(::Empty) = true
Base.isempty(::NonEmpty) = false

function PureFun.snoc(e::Empty, x)
    T = typeof(x)
    lenfm = 1
    f = cons(x, Linked.List{T}())
    m = Empty{ReverseLater{T}}()
    lenr = 0
    r = Linked.List{T}()
    NonEmpty(lenfm, f, m, lenr, r)
end

PureFun.snoc(q::NonEmpty, x) = checkq(q.lenfm, q.f, q.m, q.lenr+1, cons(x, q.r))
PureFun.head(q::NonEmpty) = head(q.f)
PureFun.tail(q::NonEmpty) = checkq(q.lenfm-1, tail(q.f), q.m, q.lenr, q.r)

function checkq(lenfm, f, m, lenr, r)
    if lenr<=lenfm 
        checkf(lenfm, f, m, lenr, r)
    else 
        checkf(lenfm+lenr, f, snoc(m, ReverseLater(r)), 0, empty(r))
    end
end

checkf(lenfm, f::Linked.Empty, m::Empty, lenr, r) = Empty{eltype(f)}()
function checkf(lenfm, f::Linked.Empty, m::NonEmpty, lenr, r)
    NonEmpty(lenfm, force(head(m)), tail(m), lenr, r)
end
checkf(lenfm, f, m, lenr, r) = NonEmpty(lenfm, f, m, lenr, r)


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


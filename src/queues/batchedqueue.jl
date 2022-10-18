module Batched

using ..PureFun
using ..PureFun.Linked

"""
    PureFun.Batched.Queue{T}()
    PureFun.Batched.Queue(iter)

Batched Queues are the simplest of the purely functional queue implementations,
and therefore the fastest for most operations. However, this queue has
worst-case linear complexity. In non-persistent settings, the worst-case cost
is guaranteed to be rare, so overall the queue has amortized constant time
complexity. In settings where a given queue can have multiple logical futures
(e.g. when multiple threads are accessing the same queue), this queue's overall
performance can degrade to O(n).

# Examples
```@jldoctest
julia> abc = PureFun.Batched.Queue('a':'c')
PureFun.Batched.Queue{Char}
a
b
c


julia> snoc(abc, 'd')
PureFun.Batched.Queue{Char}
a
b
c
d
```
"""
struct Queue{T} <: PureFun.PFQueue{T}
    front::Linked.List{T}
    rear::Linked.List{T}
    length::Int
end

front(q::Queue) = q.front
rear(q::Queue) = q.rear
PureFun.empty(q::Queue{T}) where T = Queue{T}(empty(front(q)), empty(rear(q)), 0)
Base.length(q::Queue) = q.length
Base.isempty(q::Queue) = length(q) == 0

Queue{T}() where T = Queue(Linked.List{T}(), Linked.List{T}(), 0)

function checkf(f::Linked.Empty, r::Linked.NonEmpty, len)
    _split_rear(f, r, len)
    #Queue(reverse(r), empty(r), len)
end
checkf(f, r, len) = Queue(f, r, len)

function checkr(f::Linked.NonEmpty, r::Linked.Empty, len)
    _split_front(f, r, len)
    #Queue(reverse(r), empty(r))
end
checkr(f, r, len) = Queue(f, r, len)

function _split(xs, at)
    rest = xs
    top = empty(xs)
    while !isempty(rest) && at > 0
        top = cons(head(rest), top)
        rest = tail(rest)
        at -= 1
    end
    return reverse(top), rest
end

function _split_rear(f, r, len)
    nu_r, nu_f = _split(r, cld(len, 2))
    Queue(reverse(nu_f), nu_r, len)
end

function _split_front(f, r, len)
    nu_f, nu_r = _split(f, cld(len, 2))
    Queue(nu_f, reverse(nu_r), len)
end

function PureFun.head(q::Queue)
    isempty(q) && throw(BoundsError(q, 1))
    f = front(q)
    isempty(f) ? rear(q)[1] : f[1]
end
PureFun.snoc(q::Queue, x) = checkf(front(q), cons(x, rear(q)), length(q) + 1)
function PureFun.tail(q::Queue)
    isempty(q) && throw(BoundsError(q, 1))
    f = front(q)
    isempty(f) && return empty(q)
    checkf(tail(f), rear(q), length(q)-1)
end

Queue(iter) = foldl(push, iter, init=Queue{eltype(iter)}())

function Base.last(q::Queue)
    isempty(q) && throw(BoundsError(q, 1))
    r = rear(q)
    isempty(r) ? front(q)[1] : r[1]
end

PureFun.cons(x, q::Queue) = checkr(cons(x, front(q)), rear(q), length(q) + 1)
function PureFun.pop(q::Queue)
    isempty(q) && throw(BoundsError(q, 1))
    r = rear(q)
    isempty(r) && return empty(q)
    checkr(front(q), tail(r), length(q)-1)
end

Base.iterate(q::Queue) = isempty(q) ? nothing : iterate(q, (front(q), rear(q)))

function Base.iterate(q::Queue, state)
    f, r = state
    !isempty(f) && return (head(f), (tail(f), r))
    isempty(r) && return nothing
    nu = reverse(r)
    head(nu), (tail(nu), empty(r))
end

function Base.reverse(q::Queue)
    isempty(q) ? q : Queue(rear(q), front(q), length(q))
end
Iterators.reverse(q::Queue) = Base.reverse(q)

end

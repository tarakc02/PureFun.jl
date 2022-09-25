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
end

front(q::Queue) = q.front
rear(q::Queue) = q.rear
Base.isempty(q::Queue) = isempty(front(q))
PureFun.empty(q::Queue{T}) where T = Queue{T}(empty(front(q)), empty(rear(q)))

Queue{T}() where T = Queue(Linked.List{T}(), Linked.List{T}())

function checkf(f::Linked.Empty, r::Linked.NonEmpty)
    Queue(reverse(r), empty(r))
end
checkf(f, r) = Queue(f, r)

PureFun.head(q::Queue) = isempty(q) ? throw(BoundsError(q, 1)) : head(front(q))
PureFun.snoc(q::Queue, x) = checkf(front(q), cons(x, rear(q)))
PureFun.tail(q::Queue) = isempty(q) ? throw(MethodError(tail, q)) : checkf(tail(front(q)), rear(q))

function Queue(iter)
    l = Linked.List(iter)
    Queue(l, empty(l))
end

end

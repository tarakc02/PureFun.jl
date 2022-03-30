module Batched

using ...PureFun
using ...PureFun.Lists.Linked

struct Queue{T} <: PureFun.PFQueue{T}
    front::Linked.List{T}
    rear::Linked.List{T}
end

#Empty{T} = Queue{T, Linked.Empty{T}, Linked.Empty{T}} where {T}
#NonEmpty{T} = Queue{T, Linked.NonEmpty{T}, R} where {R <: Linked.List{T}}

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

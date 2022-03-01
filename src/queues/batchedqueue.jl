module Batched

using ...PureFun
using ...PureFun.Lists.Linked

struct Queue{T, F, R} <: PureFun.PFQueue{T} where {F <: Linked.List{T}, R <: Linked.List{T}}
    front::F
    rear::R
end

Empty{T} = Queue{T, Linked.Empty{T}, Linked.Empty{T}} where {T}
NonEmpty{T} = Queue{T, Linked.NonEmpty{T}, R} where {R <: Linked.List{T}}

front(q::Queue) = q.front
rear(q::Queue) = q.rear
Base.isempty(q::Empty) = true
Base.isempty(q::NonEmpty) = false
PureFun.empty(q::NonEmpty{T}) where T = Empty{T}()
PureFun.empty(q::Empty) = q

function Queue(f::Linked.List{T}, r::Linked.List{T}) where {T}
    Queue{T, typeof(f), typeof(r)}(f, r)
end

Queue{T}() where T = Queue(Linked.List{T}(), Linked.List{T}())

function checkf(f::Linked.Empty, r::Linked.NonEmpty)
    Queue(reverse(r), empty(r))
end
checkf(f, r) = Queue(f, r)

Base.first(q::NonEmpty) = first(front(q))
PureFun.snoc(q::Queue, x) = checkf(front(q), cons(x, rear(q)))
PureFun.tail(q::NonEmpty) = checkf(tail(front(q)), rear(q))

function Queue(iter)
    l = Linked.List(iter)
    Queue(l, empty(l))
end

end

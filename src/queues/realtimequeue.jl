module RealTime

using ..PureFun
using ..PureFun.Lazy
using ..PureFun.Linked

struct Queue{T} <: PureFun.PFQueue{T}
    front::Lazy.Stream{T}
    rear::Linked.List{T}
    schedule::Lazy.Stream{T}
end

front(q::Queue) = q.front
rear(q::Queue) = q.rear
sched(q::Queue) = q.schedule
Base.isempty(q::Queue) = isempty(front(q))
Base.empty(q::Queue) = Queue(empty(front(q)), empty(rear(q)), empty(sched(q)))

Queue{T}() where T = Queue(Lazy.Stream{T}(), Linked.List{T}(), Lazy.Stream{T}())

function rotate(f::Lazy.Empty{T}, r::Linked.NonEmpty{T}, s::Lazy.Stream) where T
    @cons T head(r) s
end

function rotate(f::Lazy.NonEmpty{T}, r::Linked.NonEmpty{T}, s::Lazy.Stream{T}) where T 
    cc = @cons T head(r) s
    @cons T head(f) rotate(tail(f), tail(r), cc)
end

function exec(f, r, s::Lazy.NonEmpty) 
    # forcing this suspension
    tmp = head(s)
    Queue(f, r, tail(s))
end
function exec(f, r, s::Lazy.Empty)
    f_prime = rotate(f, r, s)
    Queue(f_prime, empty(r), f_prime)
end

PureFun.head(q::Queue) = head(front(q))
PureFun.snoc(q::Queue, x) = exec(front(q), cons(x, rear(q)), sched(q))
PureFun.tail(q::Queue) = exec(tail(front(q)), rear(q), sched(q))

function Queue(iter)
    l = Lazy.Stream(iter)
    Queue(l, Linked.List{eltype(iter)}(), l)
end

function Base.show(::IO, ::MIME"text/plain", bq::Queue)
    println("a realtime queue type $(typeof(bq))")
    !isempty(bq) || return nothing
    println("next element: $(head(bq))")
end

end

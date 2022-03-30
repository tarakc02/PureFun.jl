module RealTime

using ...PureFun
using ...PureFun.Lazy
using ...PureFun.Lists.Linked

struct Queue{T, F, R, S} <: PureFun.PFQueue{T} where {F <: Lazy.Stream{T}, R <: Linked.List{T}, S <: Lazy.Stream{T}}
    front::F
    rear::R
    schedule::S
end

Empty{T} = Queue{T, Lazy.Empty{T}, Linked.Empty{T}, Lazy.Empty{T}} where {T}
NonEmpty{T} = Queue{T, Lazy.NonEmpty{T}, R, S} where {R <: Linked.List{T}, S <: Lazy.Stream{T}}

front(q::Queue) = q.front
rear(q::Queue) = q.rear
sched(q::Queue) = q.schedule
Base.isempty(q::Empty) = true
Base.isempty(q::NonEmpty) = false
PureFun.empty(q::NonEmpty{T}) where T = Empty{T}()
PureFun.empty(q::Empty) = q

function Queue(f::Lazy.Stream{T}, r::Linked.List{T}, s::Lazy.Stream{T}) where {T}
    Queue{T, typeof(f), typeof(r), typeof(s)}(f, r, s)
end

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

PureFun.head(q::NonEmpty) = head(front(q))
PureFun.snoc(q::Queue, x) = exec(front(q), cons(x, rear(q)), sched(q))
PureFun.tail(q::NonEmpty) = exec(tail(front(q)), rear(q), sched(q))

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

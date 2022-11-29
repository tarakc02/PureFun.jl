module HoodMelville

using PureFun
using PureFun.Linked

struct Idle end

struct Reversing{T}
    ok::Int
    f::Linked.List{T}
    fp::Linked.List{T}
    r::Linked.List{T}
    rp::Linked.List{T}
end

struct Appending{T}
    ok::Int
    fp::Linked.List{T}
    rp::Linked.List{T}
end

struct Done{T}
    newf::Linked.List{T}
end

const RotationState{T} = Union{ Idle, Reversing{T}, Appending{T}, Done{T} }

struct Queue{T} <: PureFun.PFQueue{T}
    lenf::Int
    f::Linked.List{T}
    state::RotationState{T}
    lenr::Int
    r::Linked.List{T}
end

exec(state) = state
exec(st::Reversing) = execr(st.ok, st.f, st.fp, st.r, st.rp)
function execr(ok, f, fp, r, rp)
    isempty(f) ?
        Appending(ok, fp, cons(head(r), rp)) :
        Reversing(ok+1, tail(f), cons(head(f), fp), tail(r), cons(head(r), rp))
end

exec(st::Appending) = execa(st.ok, st.fp, st.rp)
function execa(ok, fp, rp)
    ok == 0 ? Done(rp) : Appending(ok-1, tail(fp), cons(head(fp), rp))
end

invalidate(state) = state
invalidate(st::Reversing) = invalidater(st.ok, st.f, st.fp, st.r, st.rp)
invalidate(st::Appending) = invalidatea(st.ok, st.fp, st.rp)
invalidater(ok, f, fp, r, rp) = Reversing(ok-1, f, fp, r, rp)
invalidatea(ok, fp, rp) = ok == 0 ? Done(tail(rp)) : Appending(ok-1, fp, rp)

function exec2(lenf, f, state, lenr, r)
    st = exec(exec(state))
    _construct(st, lenf, f, lenr, r)
end
_construct(st::Done, lenf, f, lenr, r) = Queue(lenf, st.newf, Idle(), lenr, r)
_construct(newstate, lenf, f, lenr, r) = Queue(lenf, f, newstate, lenr, r)

function check(lenf, f, state, lenr, r)
    lenr <= lenf && return _construct(exec(state), lenf, f, lenr, r)
    #lenr <= lenf && return exec2(lenf, f, state, lenr, r)
    newstate = Reversing(0, f, empty(f), r, empty(r))
    exec2(lenf+lenr, f, newstate, 0, empty(r))
end

function Base.empty(q::Queue{T}) where T
    Queue(0, Linked.List{T}(), Idle(), 0, Linked.List{T}())
end
Base.isempty(q::Queue) = q.lenf == 0

PureFun.snoc(q::Queue, x) = check(q.lenf, q.f, q.state, q.lenr+1, cons(x, q.r))
PureFun.head(q::Queue) = _head(q.lenf, q.f, q.state, q.lenr, q.r)
PureFun.tail(q::Queue) = _tail(q.lenf, q.f, q.state, q.lenr, q.r)
_head(lenf, f, state, lenr, r) = isempty(f) ? throw("Queue is empty") : head(f)
function _tail(lenf, f, state, lenr, r)
    isempty(f) ?
        throw("Queue is empty") :
        check(lenf-1, tail(f), invalidate(state), lenr, r)
end

@doc raw"""

    HoodMelville.Queue{T}()
    HoodMelville.Queue(iter)

`HoodMelville.Queue`s require worst-case constant time for all 3 queue
operations. Unlike the [`PureFun.RealTime.Queue`](@ref), the Hood-Melville
queue does not use lazy evaluation, as it more explicitly schedules incremental
work during each operation, smoothing out the costs of rebalancing across cheap
operations. Since this requires doing rebalancing work before it becomes
necessary, the Hood-Melville queues can end up doing unnecessary work, leading
to higher on-average overheads. Use when worst-case performance is more
important than average performance.

"""
function Queue(iter)
    T = Base.@default_eltype(iter)
    lenfm = length(iter)
    f = Linked.List(iter)
    Queue(lenfm, f, Idle(), 0, empty(f))
end

Queue{T}() where T = Queue(0, Linked.List{T}(), Idle(), 0, Linked.List{T}())

end

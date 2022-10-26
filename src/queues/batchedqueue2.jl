module Batched

using ..PureFun

function _myname end

# types, accessors, constructors, etc. {{{
#struct Queue{T,L} <: PureFun.PFQueue{T} where {L <: PureFun.PFList{T}}
#    front::L
#    rear::L
#    flen::Int
#    rlen::Int
#end

abstract type Queue{T} <: PureFun.PFQueue{T} end

macro deque(Name, ListType)
    :(
    struct $Name{T} <: Queue{T}
        front::$(esc(ListType)){T}
        rear::$(esc(ListType)){T}
        flen::Int
        rlen::Int
        function $Name{T}() where T
            new{T}($(esc(ListType)){T}(), $(esc(ListType)){T}(), 0, 0)
        end
        function $Name(iter)
            f = $(esc(ListType))(iter)
            r = empty(f)
            T = eltype(f)
            _split_front($Name{T}, f, r, length(f), 0)
        end
        function $Name{T}(f, r, flen, rlen) where T
            new{T}(f, r, flen, rlen)
        end
        function $Name(f, r, flen, rlen)
            new{eltype(f)}(f, r, flen, rlen)
        end
    end;
    PureFun.Batched._myname(::$(esc(Name))) = $(esc(Name))
   )
end

front(q::Queue) = q.front
rear(q::Queue) = q.rear
function Base.empty(q::Queue)
    typeof(q)()
end
function Base.empty(q::Queue, ::Type{T}) where T
    f = empty(front(q), T)
    r = empty(rear(q), T)
    _myname(q)(f, r, 0, 0)
end
Base.length(q::Queue) = q.flen + q.rlen
Base.isempty(q::Queue) = length(q) == 0

#Queue(iter, L=PureFun.Linked.List) = foldl(push, iter, init=Queue{eltype(iter)}(L))
#Queue{T}(L = PureFun.Linked.List) where T = Queue{T,L{T}}(L{T}(), L{T}(), 0, 0)
#function Queue(f::F, r::R, flen, rlen) where {T, F <: PureFun.PFList{T}, R <: PureFun.PFList{T}}
#    L = PureFun.container_type(f)
#    Queue{T,L}(f, r, flen, rlen)
#end
# }}}

# re-balancing etc. {{{
function checkf(T, f, r, lenf, lenr)
    isempty(f) ? _split_rear(T, f, r, lenf, lenr) : T(f, r, lenf, lenr)
end
function checkr(T, f, r, lenf, lenr)
    isempty(r) ? _split_front(T, f, r, lenf, lenr) : T(f, r, lenf, lenr)
end

"""
    _split_reverse(xs)

Takes some elements (how many is an implementation detail) off the end of `xs`
and reverses them. Returns the reversed sequence (as the same list type as
`xs`), the remaining truncated sequence, and the new length of the truncated
sequence

"""
function _split_reverse(xs)
    len = length(xs)
    at = cld(len, 2)
    rest = xs
    restlen = 0
    top = empty(xs)
    while !isempty(rest) && at > 0
        top = cons(head(rest), top)
        rest = tail(rest)
        at -= 1
        restlen += 1
    end
    return reverse(top), reverse(rest), restlen
end

function _split_reverse(xs::PureFun.RandomAccess.List)
    f,r = PureFun.RandomAccess.halfish(xs)
    f, reverse(r), length(f)
end

function _split_reverse(xs::PureFun.Chunky.List)
    isempty(xs) && return xs, xs, 0
    cs = PureFun.Chunky.chunks(xs)
    ck = popfirst(cs)
    if isempty(ck) && length(first(cs)) > 1
        c = first(cs)
        return (typeof(xs)(PureFun.Chunky.initialize(c[1], empty(xs))),
                typeof(xs)(reverse(popfirst(c))), 1)
    end
    _f, _r, bleh = _split_reverse(cs)
    f = typeof(xs)(_f)
    r = isempty(_r) ?
        typeof(xs)(_r) :
        typeof(xs)( reverse(_r[1]) ⇀ popfirst(map(PureFun.Contiguous.reverse_fast, _r)))
    f, r, length(f)
end

function _split_rear(T, f, r, lenf, lenr)
    nu_r, nu_f, nu_lenr = _split_reverse(r)
    T(nu_f, nu_r, lenr-nu_lenr, nu_lenr)
end

function _split_front(T, f, r, lenf, lenr)
    nu_f, nu_r, nu_lenf = _split_reverse(f)
    T(nu_f, nu_r, nu_lenf, lenf-nu_lenf)
end
# }}}

# queue + list methods {{{
function PureFun.head(q::Queue)
    isempty(q) && throw(BoundsError(q, 1))
    f = front(q)
    isempty(f) ? rear(q)[1] : f[1]
end
PureFun.snoc(q::Queue, x) = checkf(typeof(q), front(q), cons(x, rear(q)), q.flen, q.rlen+1)
function PureFun.tail(q::Queue)
    isempty(q) && throw(BoundsError(q, 1))
    f = front(q)
    isempty(f) && return empty(q)
    checkf(typeof(q), tail(f), rear(q), q.flen-1, q.rlen)
end

function Base.last(q::Queue)
    isempty(q) && throw(BoundsError(q, 1))
    r = rear(q)
    isempty(r) ? front(q)[1] : r[1]
end

function PureFun.cons(x, q::Queue)
    checkr(typeof(q), cons(x, front(q)), rear(q), q.flen + 1, q.rlen)
end
function PureFun.pop(q::Queue)
    isempty(q) && throw(BoundsError(q, 1))
    r = rear(q)
    isempty(r) && return empty(q)
    checkr(typeof(q), front(q), tail(r), q.flen, q.rlen-1)
end
# }}}

# etc. {{{
function Base.reverse(q::Queue)
    isempty(q) ? q : typeof(q)(rear(q), front(q), q.rlen, q.flen)
end
Iterators.reverse(q::Queue) = Base.reverse(q)

function Base.getindex(q::Queue, ix)
    if ix <= q.flen
        front(q)[ix]
    elseif ix <= q.flen+q.rlen
        rear(q)[length(q)-ix+1]
    else
        throw(BoundsError(q, ix))
    end
end

function Base.setindex(q::Queue, value, i)
    if i <= q.flen
        typeof(q)(setindex(front(q), value, i), rear(q), q.flen, q.rlen)
    elseif i <= q.flen+q.rlen
        typeof(q)(front(q), setindex(rear(q), value, length(q)-i+1), q.flen, q.rlen)
    else
        throw(BoundsError(q, i))
    end
end

# reverse l2 and put it on top of l1
function _revtop(l1::PureFun.Linked.List, l2::PureFun.Linked.List)
    foldl(pushfirst, l2, init=l1)
end

# for chunky lists, if chunks are bigger then this is going to be faster,
# even though it looks worse
_revtop(l1, l2) = reverse(l2) ⧺ l1

function PureFun.append(q1::Queue{T}, q2::Queue{T}) where {T}
    r = rear(q2) ⧺ foldl(pushfirst, front(q2), init=rear(q1))
    #r = rear(q2) ⧺ _revtop(rear(q1), front(q2))
    typeof(q1)(front(q1), r, q1.flen, q1.rlen+q2.flen+q2.rlen)
end

function Base.map(f, q::Queue)
    _myname(q)(map(f, front(q)), map(f, rear(q)), q.flen, q.rlen)
end

struct Init end

function Base.mapreduce(f, op, xs::Queue; init=Init())
    isempty(xs) && init isa Init && return Base.reduce_empty(op, eltype(xs))
    isempty(xs) && return init
    init isa Init ?
        op(mapreduce(f, op, front(xs)), mapreduce(f, op, rear(xs))) :
        op(init, op(mapreduce(f, op, front(xs)), mapreduce(f, op, rear(xs))))
    #rf = init isa Init ?
    #    mapreduce(f, op, front(xs)) :
    #    mapreduce(f, op, front(xs), init=init)
    #mapreduce(f, op, rear(xs), init=rf)
end

# }}}

prepare_front(xs) = collect(xs)
prepare_rear(xs) = reverse!(collect(xs))

function Base.iterate(q::Queue)
    cq = vcat(prepare_front(front(q)),
              prepare_rear(rear(q)))
    nxt = iterate(cq)
    nxt === nothing && return nothing
    nxt[1], (cq, nxt[2])
end

function Base.iterate(q::Queue, state)
    nxt = iterate(state[1], state[2])
    nxt === nothing && return nothing
    nxt[1], (state[1], nxt[2])
end

end

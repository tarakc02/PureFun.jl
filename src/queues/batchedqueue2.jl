module Batched

using ..PureFun

function _myname end

# types, accessors, constructors, etc. {{{
abstract type Queue{T} <: PureFun.PFList{T} end

@doc raw"""

    Batched.@deque Name ListType

Deques are like lists but with symmetric efficient operations on the front
(`pushfirst`, `popfirst`, `first`) and the back (`push`, `pop`, `last`). The
`Batched.@deque` [functor](https://ocaml.org/docs/functors) takes any existing
list implementation (`ListType`), and makes it double-ended. The
`Batched.@deque` works by batching occasional reversals (which are
$\mathcal{O}(n)$) so that all oeprations require *amortized* constant time.

# Examples

```jldoctest
julia> Batched.@deque Deque PureFun.Linked.List

julia> d = Deque{Int}()
0-element Deque{Int64}


julia> 1 ⇀ 2 ⇀ 3 ⇀ d
3-element Deque{Int64}
1
2
3


julia> alpha = Deque('a':'z')
26-element Deque{Char}
a
b
c
d
e
f
g
...

julia> first(alpha), last(alpha)
('a', 'z')

julia> alpha |> pop |> last
'y': ASCII/Unicode U+0079 (category Ll: Letter, lowercase)

julia> alpha |> popfirst |> first
'b': ASCII/Unicode U+0062 (category Ll: Letter, lowercase)
```
"""
macro deque(Name, ListType)
    :(
    struct $Name{T} <: Queue{T}
        front::$(esc(ListType)){T}
        rear::$(esc(ListType)){T}
        function $Name{T}() where T
            new{T}($(esc(ListType)){T}(), $(esc(ListType)){T}())
        end
        function $Name(iter)
            f = $(esc(ListType))(iter)
            r = empty(f)
            T = eltype(f)
            _split_front($Name{T}, f, r)
        end
        function $Name{T}(f, r) where T
            new{T}(f, r)
        end
        function $Name(f, r)
            new{eltype(f)}(f, r)
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
    _myname(q)(f, r)
end
Base.length(q::Queue) = length(front(q)) + length(rear(q))
Base.isempty(q::Queue) = isempty(front(q)) && isempty(rear(q))

# }}}

# re-balancing etc. {{{
checkf(T, f, r) = isempty(f) ? _split_rear(T, f, r) : T(f, r)
checkr(T, f, r) = isempty(r) ? _split_front(T, f, r) : T(f, r)

function _split_reverse(xs)
    f,r = halfish(xs)
    f, reverse(r)
end

function _split_rear(T, f, r)
    nu_r, nu_f = _split_reverse(r)
    T(nu_f, nu_r)
end

function _split_front(T, f, r)
    nu_f, nu_r = _split_reverse(f)
    T(nu_f, nu_r)
end
# }}}

# queue + list methods {{{
function PureFun.head(q::Queue)
    isempty(q) && throw(BoundsError(q, 1))
    f = front(q)
    isempty(f) ? rear(q)[1] : f[1]
end
PureFun.snoc(q::Queue, x) = checkf(typeof(q), front(q), cons(x, rear(q)))
function PureFun.tail(q::Queue)
    isempty(q) && throw(BoundsError(q, 1))
    f = front(q)
    isempty(f) && return empty(q)
    checkf(typeof(q), tail(f), rear(q))
end

function Base.last(q::Queue)
    isempty(q) && throw(BoundsError(q, 1))
    r = rear(q)
    isempty(r) ? front(q)[1] : r[1]
end

function PureFun.cons(x, q::Queue)
    checkr(typeof(q), cons(x, front(q)), rear(q))
end
function PureFun.pop(q::Queue)
    isempty(q) && throw(BoundsError(q, 1))
    r = rear(q)
    isempty(r) && return empty(q)
    checkr(typeof(q), front(q), tail(r))
end
# }}}

# etc. {{{
function Base.reverse(q::Queue)
    isempty(q) ? q : typeof(q)(rear(q), front(q))
end
Iterators.reverse(q::Queue) = Base.reverse(q)

function Base.getindex(q::Queue, ix)
    ix <= length(front(q)) ? front(q)[ix] : rear(q)[length(q)-ix+1]
end

function Base.setindex(q::Queue, value, i)
    i <= length(front(q)) ?
        typeof(q)(setindex(front(q), value, i), rear(q)) :
        typeof(q)(front(q), setindex(rear(q), value, length(q)-i+1))
end

function PureFun.append(q1::Queue{T}, q2::Queue{T}) where {T}
    r = rear(q2) ⧺ foldl(pushfirst, front(q2), init=rear(q1))
    typeof(q1)(front(q1), r)
end

Base.map(f, q::Queue) = _myname(q)(map(f, front(q)), map(f, rear(q)))

struct Init end

function Base.mapreduce(f, op, xs::Queue; init=Init())
    isempty(xs) && init isa Init && return Base.reduce_empty(op, eltype(xs))
    isempty(xs) && return init
    init isa Init ?
        op(mapreduce(f, op, front(xs)), mapreduce(f, op, rear(xs))) :
        op(init, op(mapreduce(f, op, front(xs)), mapreduce(f, op, rear(xs))))
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

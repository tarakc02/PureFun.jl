export cons, @cons, snoc, head, tail, insert, member, lookup,
       merge, find_min, delete_min, ⧺, is_empty

abstract type AbList{T} end
abstract type AbStack{T} <: AbList{T} end

function is_empty end

"""
    cons(x, xs)
    @cons(x_expr, xs_expr)
Return a container with the same type as `xs`, with `x` as the head element and
`xs` as the tail. `@cons` systematically suspends every cell in the list.
"""
function cons end

"""
    head(s)
    tail(s)

Access the first element (`head`) or the remaining elements (`tail`) of `s`
"""
function head end
function tail end

function take end
function drop end
abstract type AbSet{T} <: AbstractSet{T} end

function insert end
function member end


abstract type AbQueue{T} end

function snoc end

struct Ordered{T, O <: Base.Order.Ordering}
    elem::T
    order::O
end

ordering(x::Ordered) = x.order
Ordered{T}() where T = Ordered{T, Base.Order.Forward}()
lt(x::Ordered{T, O}, y) where {T, O} = Base.Order.lt(ordering(x), x, y)


abstract type AbFiniteMap{K, V} <: AbstractDict{K, V} end
function bind end
function lookup end

abstract type AbHeap end
function merge end
function find_min end
function delete_min end

function ⧺ end

Base.eltype(q::AbQueue{T}) where T = T
Base.iterate(q::AbQueue) = is_empty(q) ? nothing : (head(q), tail(q))
Base.iterate(q::AbQueue, state) = is_empty(state) ? nothing : (head(state), tail(state))

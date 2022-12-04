"""
    PFQueue{T}

Supertype for purely functional FIFO queues with elements of type `T`.

A `PFQueue` implements `snoc` (equivalent to `push`), `head`, and `tail`

See also [`PureFun.Batched.Queue`](@ref), [`PureFun.Bootstrapped.Queue`](@ref),
and [`PureFun.RealTime.Queue`](@ref)
"""
abstract type PFQueue{T} end

"""
    snoc(xs::PFQueue, x)
    push(xs::PFQueue, x)

Return the `PFQueue` that results from adding an element to the rear of `xs`.
"`snoc` is [`cons`](@ref) from the right."
"""
function snoc end

"""
    push(xs::PFQueue, x)
    snoc(xs::PFQueue, x)

Return the `PFQueue` that results from adding an element to the rear of `xs`.
"""
push(xs::PFQueue, x) = snoc(xs, x)
pushfirst(xs::PFQueue, x) = cons(x, xs)

Base.filter(f, q::PFQueue) = foldl(push, Iterators.filter(f, q), init=empty(q))
Base.map(f, q::PFQueue) = mapfoldl(f, push, q, init=empty(q, infer_return_type(f, l)))

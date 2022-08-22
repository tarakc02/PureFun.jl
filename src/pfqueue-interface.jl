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

Equivalent to [`snoc`](@ref)
"""
push(xs::PFQueue, x) = snoc(xs, x)

#function Base.length(xs::PFQueue)
#    l = 0
#    while !isempty(xs)
#        xs = tail(xs)
#        l += 1
#    end
#    l
#end


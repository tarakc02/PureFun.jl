"""
    PFHeap{T, O<:Base.Order.Ordering}

Supertype for purely functional heaps (aka priority queues) with elements of
type `T` and ordering `O`. These datastructures give fast access to the minimum
element, where comparisons are based on the supplied ordering.

A `PFHeap` implements `push`, `minimum`, `delete_min`, and `merge`.
"""
abstract type PFHeap{T,O<:Base.Order.Ordering} end

"""
    delete_min(xs::PFHeap)

return a new heap that is the result of deleting the minimum element from `xs`,
according to the ordering of `xs`.
"""
function delete_min end
function delete end

"""
    minimum(xs::PFHeap)

Return the smallest element in `xs`, according to its ordering. Since heaps
iterate in order, this is identical to `first` for heaps.
"""
Base.minimum(xs::PFHeap) = throw(MethodError(minimum, (xs,)))

"""
    push(xs::PFHeap, x)

Return the `PFHeap` that results from adding `x` to the collection.
"""
push(xs::PFHeap, x) = throw(MethodError(push, (xs, x)))

Base.iterate(iter::PFHeap) = isempty(iter) ? nothing : (minimum(iter), iter)
function Base.iterate(::PFHeap, state)
    nxt = delete_min(state)
    isempty(nxt) && return nothing
    return minimum(nxt), nxt
end

Base.eltype(::Type{<:PFHeap{T}}) where T = T
Base.rest(xs::PFHeap) = delete_min(xs)
Base.rest(::PFHeap, state) = delete_min(state)

"""
    merge(xs::PFHeap, ys::PFHeap)

Return a new heap with the merged contents of `xs` and `ys` (`xs` and `ys` must
have the same ordering)
"""
Base.merge(xs::PFHeap, ys::PFHeap) = throw(MethodError(merge, (xs, ys)))

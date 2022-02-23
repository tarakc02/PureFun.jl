import Base.maximum, Base.minimum
import DataStructures.Queue, DataStructures.enqueue!

function minimum(tree::NE)
    is_empty(tree.left) && return tree.key
    return minimum(tree.left)
end

function maximum(tree::NE)
    is_empty(tree.right) && return tree.key
    return maximum(tree.right)
end

function between(tree::NE{T}, lo::T, hi::T) where {T}
    queue = Queue{T}()
    fill!(queue, tree, lo, hi)
    return queue
end

function fill!(q::Queue{T}, tree::NE{T}, lo::T, hi::T) where {T}
    lo < tree.key && fill!(q, tree.left, lo, hi)
    lo <= tree.key && hi >= tree.key && enqueue!(q, tree.key)
    hi > tree.key && fill!(q, tree.right, lo, hi)
end

fill!(::Queue{T}, ::E{T}, ::T, ::T) where {T} = nothing


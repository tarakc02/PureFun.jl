import Base.iterate
import Base.length

abstract type NodePath{T} end
struct EmptyPath{T} <: NodePath{T} end
struct NP{T} <: NodePath{T}
    element::Union{Black{T}, Red{T}}
    parent::Union{NP{T}, EmptyPath{T}}
end

is_empty(::NP) = false
is_empty(::EmptyPath) = true

find_min(node::Black{T}) where {T} = find_min(NP{T}(node, EmptyPath{T}()))

function find_min(path::NP{T}) where {T}
    l = path.element.left::Union{Red{T}, Black{T}, E{T}}
    is_empty(l) && return path
    find_min(NP{T}(l, path))
end

function next_inorder(path::NP{T}) where {T}
    r = path.element.right::Union{Red{T}, Black{T}, E{T}}
    !is_empty(r) && return find_min(NP{T}(r, path))
    is_empty(path.parent) && return EmptyPath{T}()
    cur = path
    par = cur.parent
    while (!is_empty(par) && cur.element === par.element.right::Union{Red{T}, Black{T}, E{T}})
        cur = par
        par = cur.parent
    end
    par
end

iterate(::E) = nothing
function iterate(t::RB{T}) where {T}
    min = find_min(t)
    min.element.key::T, min
end
function iterate(t::RB{T}, state::NP{T}) where {T}
    next = next_inorder(state)
    is_empty(next) && return nothing
    return next.element.key, next
end


module Linked

using ..PureFun

struct Empty{T} <: PureFun.PFList{T} end

struct NonEmpty{T} <: PureFun.PFList{T}
    head::T
    tail::Union{Empty{T}, NonEmpty{T}}
end

List{T} = Union{Empty{T}, NonEmpty{T}} where {T}

Empty(T) = Empty{T}()
Base.empty(::List{T}) where {T} = Empty{T}()

PureFun.cons(x::T, xs::List{T}) where T = NonEmpty(x, xs)
PureFun.head(l::NonEmpty) = l.head
PureFun.tail(l::NonEmpty) = l.tail

Base.isempty(::Empty) = true
Base.isempty(::NonEmpty) = false

"""
    Linked.List{T}()
    Linked.List(iter)

construct an empty linked List, or a linked list containing the elements of
`iter`.

# Parameters
`T::Type` element type (inferred if creating from `iter`)

# Examples
```jldoctest
julia> l = PureFun.Linked.List(1:3)
1
2
3


julia> m = cons(10, l)
10
1
2
3


julia> head(l)
1

julia> head(m)
10

julia> all(tail(m) .== l)
true
```
"""
List{T}() where T = Empty{T}()
List(iter::List) = iter
function List(iter)
    foldl(push, reverse(iter); init=Empty(eltype(iter)))
end

end


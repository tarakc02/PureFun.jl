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
Base.empty(::List, ::Type{U}) where U = Empty{U}()

PureFun.cons(x::T, xs::List) where T = NonEmpty(x, xs)
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
List(xs::AbstractRange) = foldr(cons, xs, init=List{eltype(xs)}())
List(xs::AbstractString) = foldr(cons, xs, init=List{eltype(xs)}())
List(xs::Vector) = foldr(cons, xs, init=List{eltype(xs)}())
function List(iter)
    o = foldl(pushfirst, iter; init=Empty(eltype(iter)))
    reverse(o)
end

PureFun.container_type(::Type{<:List{T}}) where T = List{T}
#PureFun.container_type(::List{T}) where T = List{T}

end


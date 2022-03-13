module Linked

using ...PureFun

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
    Linked.List()
    Linked.List(iter)

construct an empty linked List, or a linked list containing the elements of
`iter`
"""
List{T}() where T = Empty{T}()
List(iter::List) = iter
List(iter)  = foldr( cons, iter; init=Empty(eltype(iter)) )

end


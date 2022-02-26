module Linked

using ...PureFun

#=
## A concrete implementation

A `List` is either an empty list `Empty`, or a data element plus a pointer to
another `List`. I'm assuming a data structure like this can be efficient due to
[union splitting](https://julialang.org/blog/2018/08/union-splitting/)

=#
struct Empty{T} <: PureFun.PFList{T} end

struct NonEmpty{T} <: PureFun.PFList{T}
    head::T
    tail::Union{Empty{T}, NonEmpty{T}}
end

List{T} = Union{Empty{T}, NonEmpty{T}} where {T}

Empty(T) = Empty{T}()
Base.empty(::List{T}) where {T} = Empty{T}()

PureFun.cons(x, xs) = NonEmpty(x, xs)
Base.first(l::NonEmpty) = l.head
PureFun.tail(l::NonEmpty) = l.tail

Base.isempty(::Empty) = true
Base.isempty(::NonEmpty) = false

function Base.show(::IO, ::MIME"text/plain", s::Empty)
    print("an empty list of type $(typeof(s))")
end

PureFun.append(l::Empty{T}, s::List{T}) where T = s
PureFun.append(l::Empty, el) = cons(el, l)
PureFun.append(l::List, el) = cons(first(l), tail(l) ⧺ el)

"""
    Linked.List()
    Linked.List(iter)

construct an empty linked List, or a linked list containing the elements of
from the elements of `iter`
"""
List{T}() where T = Empty{T}()
List(iter::List) = iter
List(iter)  = foldr( cons, iter; init=Empty(eltype(iter)) )

#=
## Additional helper methods

`length` and `reverse` are useful, but require visiing every element of the
list
=#

Base.reverse(l::Empty) = l
Base.reverse(l::NonEmpty) = reverse(first(l), tail(l))
Base.reverse(h, t::Empty) = cons(h, t)
Base.reverse(h, t::NonEmpty) = reverse(t) ⧺ h

end


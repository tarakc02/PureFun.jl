module Linked

using ..PureFun
import ..PureFun.⧺

#=
## A concrete implementation

A `List` is either an empty list `Empty`, or a data element plus a pointer to
another `List`. I'm assuming a data structure like this can be efficient due to
[union splitting](https://julialang.org/blog/2018/08/union-splitting/)

=#
struct Empty{T} <: PureFun.AbList{T} end

struct NonEmpty{T} <: PureFun.AbList{T}
    head::T
    tail::Union{Empty{T}, NonEmpty{T}}
end

List{T} = Union{Empty{T}, NonEmpty{T}} where {T}

Empty(T) = Empty{T}()
Base.empty(::List{T}) where {T} = Empty{T}()

#=
    cons(x, xs)

Return a list with `x` at the head and `xs` as the tail
=#
PureFun.cons(x, xs) = NonEmpty(x, xs)
PureFun.head(l::NonEmpty) = l.head
PureFun.tail(l::NonEmpty) = l.tail

"""
    is_empty(list)

Test if `list` is empty
"""
PureFun.is_empty(::Empty) = true
PureFun.is_empty(::NonEmpty) = false

Base.iterate(::Empty) = nothing
Base.iterate(::List, ::Empty) = nothing
Base.iterate(iter::List) = head(iter), tail(iter)
Base.iterate(::List, state::List) = head(state), tail(state)
Base.eltype(::List{T}) where {T} = T

function Base.show(::IO, ::MIME"text/plain", s::Empty)
    print("an empty list of type $(typeof(s))")
end

function Base.show(::IO, ::MIME"text/plain", s::List)
    cur = s
    n = 7
    while n > 0 && !is_empty(cur)
        println(head(cur))
        cur = tail(cur)
        n -= 1
    end
    n <= 0 && println("...")
end

# For append/concatenate
⧺(l::Empty{T}, s::List{T}) where T = s
⧺(l::Empty, el) = cons(el, l)
⧺(l::List, el) = cons(head(l), tail(l) ⧺ el)

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

Base.length(::Empty) = 0
Base.length(l::NonEmpty) = 1 + length(tail(l))

Base.reverse(l::Empty) = l
Base.reverse(l::NonEmpty) = reverse(head(l), tail(l))
Base.reverse(h, t::Empty) = cons(h, t)
Base.reverse(h, t::NonEmpty) = reverse(t) ⧺ h

end


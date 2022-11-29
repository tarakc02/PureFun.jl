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

@doc raw"""
    Linked.List{T}()
    Linked.List(iter)

The `Linked.List` ($\S{2.1}$) is the simplest of the list types, and the
fastest for the primary operations, which are all $\mathcal{O}(1)$.

# Examples
```jldoctest
julia> using PureFun, PureFun.Linked
julia> l = Linked.List(1:3)
3-element PureFun.Linked.NonEmpty{Int64}
1
2
3


julia> m = pushfirst(l, 10)
4-element PureFun.Linked.NonEmpty{Int64}
10
1
2
3


julia> first(l)
1

julia> first(m)
10

julia> popfirst(m) == l
true
```
"""
List{T}() where T = Empty{T}()
List(iter::List) = iter
List(xs::AbstractRange) = foldr(cons, xs, init=List{Base.@default_eltype(xs)}())
List(xs::AbstractString) = foldr(cons, xs, init=List{Base.@default_eltype(xs)}())
List(xs::Vector) = foldr(cons, xs, init=List{Base.@default_eltype(xs)}())
function List(iter)
    o = foldl(pushfirst, iter; init=Empty(Base.@default_eltype(iter)))
    reverse(o)
end

PureFun.container_type(::Type{<:List{T}}) where T = List{T}
#PureFun.container_type(::List{T}) where T = List{T}

end


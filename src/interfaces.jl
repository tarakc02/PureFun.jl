# note: all containers are expected to have implemented `Base.isempty`

export cons, pushfirst, snoc, push,
       append, ⧺,
       head, tail,
       setindex, insert,
       delete_min, delete_max,
       delete, update_at,
       drop, pop, popfirst

import StaticArrays.pushfirst,
       StaticArrays.push,
       StaticArrays.insert,
       StaticArrays.pop,
       StaticArrays.popfirst

import Base.setindex

include("pflist-interface.jl")
include("pfqueue-interface.jl")
include("pfset-interface.jl")
include("pfheap-interface.jl")
include("pfdict-interface.jl")

function infer_return_type(f, l)
    !isempty(l) && return typeof(f(first(l)))
    T = Base.@default_eltype(Iterators.map(f, l))
    T === Union{} && return Any
    return T
end

#=

each container should implement this e.g.: container_type(::Linked.List{T}) =
Linked.List{T} useful because we're using small unions, need to keep the
broader type info sometimes. this should return a DataType that is also an
empty constructor for that type

=#
container_type(pf) = container_type(typeof(pf))
container_type(T::Type) = T

# optional method for ordered collections
function delete_max end

abstract type PFStream{T} end

# some shared implementations {{{

# implements `head` and `tail`
const PFListy{T} = Union{PFList{T}, PFQueue{T}, PFStream{T}} where T
popfirst(xs::PFListy) = tail(xs)

# iterates over elements of type T in a specified order
const PFIter{T} = Union{PFHeap{T}, PFListy{T}} where T

_return_1(x) = 1
function Base.length(xs::Union{PFIter, PFDict, PFSet})
    mapreduce(_return_1, +, xs, init = 0)
end

function Base.show(io::IO, ::MIME"text/plain", s::Union{PFIter, PFSet})
    msg = Base.IteratorSize(s) isa Union{Base.HasLength, Base.HasShape} ?
        "$(length(s))-element $(supertype(typeof(s)))" :
        "$(supertype(typeof(s)))"
    println(io, msg)
    #println("$(typeof(s))")
    cur = s
    n = 7
    for x in s
        print(io, x)
        n -= 1
        n >= 1 && print(io, "\n")
        n < 1 && break
    end
    n <= 0 && print(io, "\n...")
end

# compact (1-line) version of show
function Base.show(io::IO, s::Union{PFIter, PFSet})
    for (i, el) in enumerate(s)
        if i > 5
            print(io, "...")
            return nothing
        end
        print(io, el, ", ")
    end
end

function Base.getindex(l::PFIter, ind)
    (isempty(l) | ind < 1) && throw(BoundsError(l, ind))
    i = ind
    for el in l
        i == 1 && return el
        i -= 1
    end
    throw(BoundsError(l, ind))
end

function Base.iterate(r::Iterators.Reverse{<:PFIter{T}}) where T
    itr = r.itr
    isempty(itr) && return nothing
    rev = foldl(pushfirst, itr, init = Linked.List{T}())
    return head(rev), rev
end

function Base.iterate(::Iterators.Reverse{<:PFIter{T}}, state) where T
    st = tail(state)
    isempty(st) && return nothing
    return head(st), st
end

Base.rest(l::PFListy) = tail(l)
Base.rest(::PFListy, itr_state) = tail(itr_state)

Base.iterate(iter::PFListy) = isempty(iter) ? nothing : (head(iter), iter)
function Base.iterate(::PFListy, state)
    nxt = tail(state)
    isempty(nxt) && return nothing
    return head(nxt), nxt
end

Base.IndexStyle(::Type{<:PFIter}) = IndexLinear()
Base.IteratorSize(::Type{<:PFIter}) = Base.SizeUnknown()
Base.size(iter::PFIter) = (length(iter),)
Base.eltype(::Type{<:PFIter{T}}) where T = T
Base.firstindex(l::PFIter) = 1

# }}}

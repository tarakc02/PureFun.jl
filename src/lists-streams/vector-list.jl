module VectorCopy

using ..PureFun

struct List{T} <: PureFun.PFList{T}
    vec::Vector{T}
    head::Int
end

List{T}() where T = List(Vector{T}(), 1)
Base.empty(list::List) = List(empty(list.vec), 1)
Base.empty(list::List, ::Type{U}) where U = List(Vector{U}(), 1)
Base.isempty(l::List) = l.head > length(l.vec)

Base.length(l::List) = isempty(l) ? 0 : length(l.vec) - l.head + 1
PureFun.head(l::List) = isempty(l) ? throw(BoundsError(l, 1)) : l.vec[l.head]

function PureFun.cons(x::T, xs::List{T}) where T
    newvec = isempty(xs) ? Vector{T}() : xs.vec[xs.head:end] 
    pushfirst!(newvec, x)
    List(newvec, 1)
end

function PureFun.tail(l::List)
    isempty(l) && throw(BoundsError(l))
    List(l.vec, l.head+1)
end

List(iter::List) = iter
function List(iter)
    List(collect(iter), 1)
end

Base.iterate(iter::List) = isempty(iter) ? nothing : (iter.vec[iter.head], iter.head+1)
function Base.iterate(iter::List, state)
    state > length(iter.vec) && return nothing
    return iter.vec[state], state+1
end
struct Init end
function Base.mapreduce(f, op, l::List; init=Init())
     init isa Init ?
         mapreduce(f, op, l.vec) :
         mapreduce(f, op, l.vec, init=init)
end

Base.reverse(l::List) = isempty(l) ? l : List(reverse(l.vec[l.head:end]), 1)
function PureFun.append(l1::List, l2::List)
    List( vcat(l1.vec[l1.head:end],
               l2.vec[l2.head:end]),
         1)
end

function Base.getindex(l::List, ind)
    adj_ind = ind + l.head - 1
    @boundscheck adj_ind > length(l.vec) && throw(BoundsError(l, ind))
    l.vec[adj_ind]
end

function Base.setindex(l::List, newval, ind)
    newvec = l.vec[l.head:end]
    newvec[ind] = newval
    List(newvec, 1)
end

function PureFun.insert(l::List, ix, v)
    newvec = l.vec[l.head:end]
    insert!(newvec, ix, v)
    List(newvec, 1)
end

end



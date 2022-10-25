module VectorCopy

using ..PureFun

struct List{T} <: PureFun.PFList{T}
    vec::Vector{T}
    head::Int
end

List{T}() where T = List{T}(Vector{T}(), 1)
List(vec::Vector, head) = List{eltype(vec)}(vec, head)
Base.empty(list::List) = List{eltype(list)}()
Base.empty(list::List, ::Type{U}) where U = List{U}()
Base.isempty(l::List) = l.head > length(l.vec)

Base.length(l::List) = isempty(l) ? 0 : length(l.vec) - l.head + 1
function PureFun.head(l::List)
    @boundscheck isempty(l) && throw(BoundsError(l, 1))
    @inbounds l.vec[l.head]
end

function PureFun.cons(x, xs::List)
    newvec = isempty(xs) ? [x] : pushfirst!(xs.vec[xs.head:end], x)
    List(newvec, 1)
end

function PureFun.tail(l::List)
    @boundscheck l.head > length(l.vec) && throw(BoundsError(l, 1))
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
    _l = @view l.vec[l.head:end]
    init isa Init ?
        mapreduce(f, op, _l) :
        mapreduce(f, op, _l, init=init)
end

Base.reverse(l::List) = isempty(l) ? l : List(reverse(l.vec[l.head:end]), 1)
function PureFun.append(l1::List, l2::List)
    List( vcat(l1.vec[l1.head:end], l2.vec[l2.head:end]), 1)
end

function Base.getindex(l::List, ind)
    adj_ind = ind + l.head - 1
    @boundscheck adj_ind > length(l.vec) && throw(BoundsError(l, ind))
    @inbounds l.vec[adj_ind]
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

PureFun.container_type(::Type{<:List{T}}) where T = List{T}

end



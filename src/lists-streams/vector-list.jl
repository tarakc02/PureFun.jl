module VectorCopy

using ..PureFun

struct Empty{T} <: PureFun.PFList{T} end
struct NonEmpty{T} <: PureFun.PFList{T}
    vec::Vector{T}
    head::Int
end

List{T} = Union{Empty{T}, NonEmpty{T}} where T

List{T}() where T = Empty{T}()
Base.empty(list::List) = Empty{eltype(list)}()
Base.empty(list::List, ::Type{U}) where U = Empty{U}()
Base.isempty(l::List) = l isa Empty

Base.length(l::List) = isempty(l) ? 0 : length(l.vec) - l.head + 1
PureFun.head(l::NonEmpty) = @inbounds l.vec[l.head]

function PureFun.cons(x, xs::List)
    newvec = isempty(xs) ? [x] : pushfirst!(xs.vec[xs.head:end], x)
    NonEmpty(newvec, 1)
end

PureFun.tail(l::NonEmpty) = NonEmpty(l.vec, l.head+1)

List(iter::List) = iter
function List(iter)
    NonEmpty(collect(iter), 1)
end

Base.iterate(iter::List) = isempty(iter) ? nothing : (iter.vec[iter.head], iter.head+1)
function Base.iterate(iter::List, state)
    state > length(iter.vec) && return nothing
    return iter.vec[state], state+1
end
struct Init end
function Base.mapreduce(f, op, l::NonEmpty; init=Init())
    _l = @view l.vec[l.head:end]
    init isa Init ?
        mapreduce(f, op, _l) :
        mapreduce(f, op, _l, init=init)
end

Base.reverse(l::List) = isempty(l) ? l : NonEmpty(reverse(l.vec[l.head:end]), 1)
function PureFun.append(l1::NonEmpty, l2::NonEmpty)
    NonEmpty( vcat(l1.vec[l1.head:end], l2.vec[l2.head:end]), 1)
end

function Base.getindex(l::NonEmpty, ind)
    adj_ind = ind + l.head - 1
    @boundscheck adj_ind > length(l.vec) && throw(BoundsError(l, ind))
    @inbounds l.vec[adj_ind]
end

function Base.setindex(l::NonEmpty, newval, ind)
    newvec = l.vec[l.head:end]
    newvec[ind] = newval
    NonEmpty(newvec, 1)
end

function PureFun.insert(l::Empty, ix, v)
    @boundscheck ix == 1 || throw(BoundsError(l, ix))
    NonEmpty([v], 1)
end
function PureFun.insert(l::NonEmpty, ix, v)
    newvec = l.vec[l.head:end]
    insert!(newvec, ix, v)
    NonEmpty(newvec, 1)
end

PureFun.container_type(::Type{<:List{T}}) where T = List{T}

end



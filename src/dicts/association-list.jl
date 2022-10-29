module Association

using ..PureFun

struct Map{L,K,V} <: PureFun.PFDict{K,V} where { L<:PureFun.PFList{Pair{K,V}} }
    pairs::L
end

Base.isempty(al::Map) = isempty(al.pairs)
Base.empty(al::Map) = Map(empty(al.pairs))

function Map(l::PureFun.PFList{Pair{K,V}}) where {K,V}
    L = PureFun.container_type(l)
    Map{L,K,V}(l)
end
Map{L,K,V}() where {L,K,V} = Map{L,K,V}(L())
Map{K,V}(L=PureFun.Linked.List) where {K,V} = Map(L{Pair{K,V}}())

function list(::Type{ListType}) where ListType
    Map{ListType{Pair{K,V}}, K, V} where {K,V}
end

# once again, i'd like these to be generic but...

function (Map{PureFun.Linked.List{Pair{K,V}}, K, V} where {K,V})(iter)
    it = sort(collect(iter), rev = true)
    peek = first(it)
    peek isa Pair || return MethodError(Map, iter)
    K, V = typeof(peek[1]), typeof(peek[2])
    ps = foldl(pushfirst, it, init = PureFun.Linked.List{Pair{K,V}}())
    Map(ps)
end

function (Map{PureFun.VectorCopy.List{Pair{K,V}}, K, V} where {K,V})(iter)
    l = PureFun.VectorCopy.List(sort(collect(iter)))
    Map(l)
end

Base.length(al::Map) = length(al.pairs)

Base.iterate(d::Map) = iterate(d.pairs)
Base.iterate(d::Map, state) = iterate(d.pairs, state)

Base.setindex(l::Map, v, k) = Map(_setkey(l.pairs, Pair(k,v), k))

function _setkey(l, newpair, key)
    isempty(l)    && return cons(newpair, l)
    curkey = head(l).first
    key <  curkey && return cons(newpair, l)
    key == curkey && return cons(newpair, tail(l))
    cons(head(l), _setkey(tail(l), newpair, key))
end

function PureFun.get(d::Map, k, default)
    pairs = d.pairs
    isempty(pairs) && return default
    for kv in pairs
        kv.first == k && return kv.second
        k < kv.first  && return default
    end
    default
end

PureFun.push(d::Map, p::Pair) = PureFun.setindex(d, p[2], p[1])

end

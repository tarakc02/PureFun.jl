module AssocList

using ..PureFun

struct Map{L,K,V} <: PureFun.PFDict{K,V} where { L<:PureFun.PFList{Pair{K,V}} }
    pairs::L
end

Base.isempty(al::Map) = isempty(al.pairs)

function Map(l::PureFun.PFList{Pair{K,V}}) where {K,V}
    L = typeof(l)
    Map{L,K,V}(l)
end
Map{K,V}(L=PureFun.Linked.List) where {K,V} = Map(L{Pair{K,V}}())

function Map(iter, L=PureFun.Linked.List)
    peek = first(iter)
    peek isa Pair || return MethodError(Map, iter)
    K, V = typeof(peek[1]), typeof(peek[2])
    ps = foldl(pushfirst, iter, init = L{ Pair{K,V} }())
    Map{typeof(ps),K,V}(ps)
end

Base.length(al::Map) = length(al.pairs)

Base.iterate(d::Map) = iterate(d.pairs)
Base.iterate(d::Map, state) = iterate(d.pairs, state)

function Base.setindex(l::Map, newval, key)
    Map(cons(Pair(key,newval), l.pairs))
#    isempty(l) && return Map(cons(Pair(key,newval), l.pairs))
#    new = empty(l.pairs)
#    cur = l.pairs
#    while !isempty(cur) && head(cur).first != key
#        new = cons(head(cur), new)
#        cur = tail(cur)
#    end
#    new = cons(Pair(key,newval), new)
#    init = isempty(cur) ? cur : tail(cur)
#    Map(foldl(pushfirst, new, init=init))
end

function PureFun.get(d::Map, k, default)
    pairs = d.pairs
    while !isempty(pairs)
        cur = head(pairs)
        cur[1] == k && return cur[2]
        pairs = tail(pairs)
    end
    default
end

PureFun.push(d::Map, p::Pair) = PureFun.setindex(d, p[2], p[1])

end

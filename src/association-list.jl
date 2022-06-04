struct Assoclist{K,V} <: PureFun.PFDict{K,V}
    pairs::PureFun.Linked.List{Pair{K,V}}
end

Assoclist{K,V}() where {K,V} = Assoclist(PureFun.Linked.List{Pair{K,V}}())
PureFun.setindex(d::Assoclist, k, v) = Assoclist(cons(Pair(k,v), d.pairs))
function PureFun.get(d::Assoclist, k, default)
    pairs = d.pairs
    while !isempty(pairs)
        cur = head(pairs)
        cur[1] == k && return cur[2]
        pairs = tail(pairs)
    end
    default
end
PureFun.insert(d::Assoclist, p::Pair) = PureFun.setindex(d, p[1], p[2])
function Assoclist(iter)
    peek = first(iter)
    peek isa Pair || return MethodError(Assoclist, iter)
    K, V = typeof(peek[1]), typeof(peek[2])
    reduce(insert, iter, init=Assoclist{K,V}())
end
Base.isempty(al::Assoclist) = isempty(al.pairs)




module Assoc

const List = PureFun.VectorCopy.List

struct Dictionary{K,V} <: PFDict{K,V}
    kvs::List{Pair{K,V}}
end

function Base.get(d::Dictionary, key, default)
    for kv in d.kvs
        kvs[1] == key && return kvs[2]
    end
    throw(KeyError(key))
end

function PureFun.setindex(d::Dictionary, key, value)
end

end

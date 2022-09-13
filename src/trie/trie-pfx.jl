next_index(itr1, itr2) = 1 + min(lastindex(itr1), lastindex(itr2))

function first_nonmatch(itr1, itr2)
    for (i, (e1, e2)) in enumerate(zip(itr1, itr2))
        e1 == e2 || return i
    end
    next_index(itr1, itr2)
end

#struct Prefix{T}
#    pfx::Vector{T}
#end

#Base.iterate(p::Prefix) = iterate(p.pfx)
#Base.iterate(p::Prefix, state) = iterate(p.pfx, state)
#Base.lastindex(p::Prefix) = lastindex(p.pfx)

struct Trie{K,V}
    v::Option{V}
    prefix::Vector{K}
    edges::Map{K, Trie{K,V}}
end

_val(t, default) = isnothing(t.v) ? default : something(t.v)
prefix(t::Trie) = t.prefix

function lookup(t::Trie, keys, default)
    isempty(keys) && return default
    i = first_nonmatch(keys, prefix(trie))
    _lookup(trie, keys, i, default)
end

function _lookup(trie, query, i, default)
    plen = lastindex(prefix(trie))
    qlen = lastindex(query)
    i <= plen && return default
    (plen == qlen) && return _val(t, default)
    _lookup_remaining(edges(trie), query, i, default)
end

function _lookup_remaining(emap, query, i, default)
    t = get(emap, query[i], nothing)
    t === nothing && return default
    lookup(t, query[i:end], default)
end

#=

We find the first nonmatching index between query and current prefix. then one of:

- i == len(query) == len(pfx): we're at the node, update the value
- len(query) < i <= len(pfx): split the node at pfx[i]
- i <= len(query): setindex edges[query[i]] 

=#
function update(trie::Trie{K,V}, x, query) where {K,V}
    isempty(query) && return Trie{K,V}(Some(x), collect(query), edges(trie))
    i = first_nonmatch(query, prefix(trie))
    qlen = lastindex(query)
    plen = lastindex(prefix(trie))
    if  i == qlen == plen
        update_value(trie, x)
    elseif qlen < i <= plen
        tsplit(trie, i, query, x)
    else
        set_suffix(trie, query, i, x)
    end
end

#=

sets the suffix `query[i:end]` into `trie` with a value of `Some(x)`

=#
function set_suffix(trie, query, i, x)
    emap = edges(query)
    t = get(emap, query[i], empty(emap))
end

#=

takes a node and query and splits the node so that there is a parent node with
prefix=pfx[1:i-1] and two children, one with prefix=query[i:end] and one with
prefix=pfx[i:end]

=#
function tsplit(t::Trie, i, query, x)
    pfix = prefix(t)
    p = pfix[i]
    k = query[i]
    old_node = Trie(t.v, pfix[i:end], edgemap(t))
    new_node = Trie(Some(x), query[i:end], empty_edgemap(t))
    new_edgemap = setindex(empty_edgemap(t), old_node, p)
    new_edgemap = setindex(new_edgemap,      new_node, k)
    Trie(nothing, pfix[1:i-1], new_edgemap)
end
# }}}


function update_value(t::Trie{K,V}, x) where {K,V}
    Trie{K,V}(Something(x), prefix(t), edges(t))
end


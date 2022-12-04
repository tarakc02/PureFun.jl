```@meta
CurrentModule = PureFun
DocSetup = quote using PureFun end
```

# Dictionaries

## `RedBlack.RBDict` ($\S{3.3}$) 

```@docs
RedBlack.RBDict
```

## `Tries` ($\S{10.3.1}$)

These tries use path compression (exercise 10.10, although using the
"Compressed Trie with digit numbers" variant presented
[here](https://www.cise.ufl.edu/~sahni/dsaaj/enrich/c16/tries.htm)), resulting
in compact and efficient dictionaries

```@docs
Tries.@trie
```

## `HashTable`: $\S{10.3.1}$ exercise 10.11

Between the path-compressed tries and the ultra-fast `BitMap` used for the
edgemaps, this dictionary type is very fast for both updates and lookups.
Updates/inserts will become even more efficient once there is a fix for
[#17](@ref)

```@docs
HashTable.HashMap
```

## `Association.List`

```@docs
Association.List
```

## Function reference

```@docs
PureFun.setindex(d::PureFun.PFDict, v, i)
Base.get(d::PureFun.PFDict, key, default)
PureFun.PFDict
```

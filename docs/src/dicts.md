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

## `HashMap`: $\S{10.3.1}$ exercise 10.11

```@docs
HashMaps.@hashmap
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

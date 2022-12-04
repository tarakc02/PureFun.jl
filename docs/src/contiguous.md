```@meta
CurrentModule = PureFun
DocSetup = quote using PureFun end
```

# `PureFun.Contiguous` for small size optimizations

```@docs
PureFun.Contiguous
```

# Chunks: densely packed lists

```@docs
PureFun.Contiguous.StaticChunk
PureFun.Contiguous.VectorChunk
```

# Bits: a set requiring one integer worth of storage

```@docs
PureFun.Contiguous.Bits
```

# `bitmap`: a small dictionary

```@docs
PureFun.Contiguous.bitmap
```

# `biterate`: bit-wise iteration over single integers

[`Contiguous.bitmap`](@ref) is great if you only need a dictionary with small
integer keys, but doesn't generalize to other use-cases. `Contiguous.biterate`
takes arbitrary integers and breaks them into smaller integers suitable to be
keys in a bitmap. [`PureFun.Tries.@trie`](@ref) allows you to chain together
simpler dictionaries to build more general ones, so `biterate`, `bitmap`, and
`@trie` combine to build very efficient BitMapped tries, as described in [Fast
and Space Efficient Trie
Searches](https://www.semanticscholar.org/paper/Fast-And-Space-Efficient-Trie-Searches-Bagwell/93a1fe7f226cfbc7cb2bceac39308a66c8aef0b0)
and [Ideal Hash
Trees](https://www.semanticscholar.org/paper/Ideal-Hash-Trees-Bagwell/4fc240d0d9e690cb9b0bcb2f8a5e5ca918b01410)

```@docs
PureFun.Contiguous.biterate
```

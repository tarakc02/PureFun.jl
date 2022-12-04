```@meta
CurrentModule = PureFun
DocSetup = quote using PureFun end
```
# Lists

Provide efficient access to the front element, and can efficiently add and
remove elements from the front. Sometimes also called a "stack." Primary
operations:

- `first(xs)`: get the first element of `xs`
- `popfirst(xs)`: returns a new list that looks like `xs` but with the first
  element removed
- `pushfirst(xs, x)`: returns a new list with `x` added to the front of `xs`.
  The infix operator `⇀` (pronounced `\rightharpoonup`) is often more
  convenient. Note that it is right-associative, so `x ⇀ y ⇀ zs ` is equivalent
  to `pushfirst(pushfirst(zs, y), x)`


Additionally, PureFun.jl implements default implementations of a variety of
[Abstract
Vector](https://docs.julialang.org/en/v1/base/arrays/#Base.AbstractVector)-like
methods for list types, though they are not necessarily efficient. All of these
functions have similar meanings to their mutating (with a `!` at the end of the
function name) counterparts in `Base`. When these functions are already present
in [StaticArrays.jl](https://juliaarrays.github.io/StaticArrays.jl/stable/),
PureFun.jl just adds methods to the existing functions.

- `reverse`
- `insert`
- `getindex` (`xs[i]` to get the i-th element of `xs`)
- `setindex` (help wanted: nice syntax for non-mutating `setindex`)
- `append` (use the infix notation `xs ⧺ ys` to append `ys` to the end of `xs`)

Lists iterate in
[LIFO](https://en.wikipedia.org/wiki/Stack_(abstract_data_type)) order, and
work with a variety of built-in [higher-order
functions](https://en.wikipedia.org/wiki/Higher-order_function):

- eager versions of `map`, `filter`, `accumulate`
- `(map)foldl`, `(map)foldr`, `(map)reduce`

All of the lists types provide the same functionality and interface, but
different implementations are optimized for different use-cases and types of
operations. For example, getting or setting an index in a linked list usually
takes $\mathcal{O}(n)$ time, but `PureFun.RandomAccess.List` provides indexing
operations that take $\mathcal{O}(\log{_2}n)$. All of the list
implementations in PureFun.jl inherit from the abstract type `PureFun.PFList`.
Complexities presented below are worst-case, unless stated otherwise.

## `Linked.List` ($\S{2.1}$)

```@docs
Linked.List
```


## `RandomAccess.List` ($\S{9.3.1}$)

```@docs
RandomAccess.List
```

## `Catenable.List` ($\S{10.2.1}$)

```@docs
Catenable.List
```

## `VectorCopy.List`: an immutable wrapper for `Base.Vector`

```@docs
VectorCopy.List
```

## CPU-cache friendly lists: `Chunky.@list`

Pointer-based data structures are at a disadvantage performance-wise when
compared to arrays and vectors. Memory accesses are high-latency operations, so
that observed performance will be determined by the number of cache misses
regardless of the on-paper complexity guarantees of an algorithm. The
`VectorCopy.List` gets around this issue by storing adjacent list values
physically close to each other in contiguous memory, but write operations
require allocating $\mathcal{O}(n)$ memory, which quickly becomes prohibitive.
The [unrolled linked list](https://en.wikipedia.org/wiki/Unrolled_linked_list)
strikes a compromise between the two extremes by storing chunks of values
together in each list cell. `PureFun.Chunky.@list` converts any list type to a
"chunky" version, using one of the chunk types provided by
[`PureFun.Contiguous`](@ref):

- [`Contiguous.StaticChunk{N}`](@ref): Backed by `StaticArrays.SVector`
- [`Contiguous.VectorChunk{N}`](@ref): Backed by `Base.Vector`

```@docs
Chunky.@list
```

For more on cache-friendly data structures and the role of cache misses on
performance:

- [Data Locality](https://gameprogrammingpatterns.com/data-locality.html)
- [Going nowhere faster](https://youtu.be/2EWejmkKlxs) 
- [Gallery of processor cache
  effects](http://igoro.com/archive/gallery-of-processor-cache-effects/)

## Custom double-ended queue: $\S{5.2}$ (excercise 5.1)

```@docs
Batched.@deque
```

## Function reference

```@docs
PureFun.pushfirst(::PureFun.PFList, x)
PureFun.popfirst(::PureFun.PFListy)
PureFun.append
PureFun.insert(::PureFun.PFList, i, v)
PureFun.setindex(::PureFun.PFList, v, i)
PureFun.halfish
```


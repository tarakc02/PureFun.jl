```@meta
CurrentModule = PureFun
DocSetup = quote using PureFun end
```

# Heaps

Heaps, also known as *priority queues*, provide efficient access to the
*minimum element* in a collection, and an efficient *delete-the-minimum*
operation as well as a *merge* operation that takes two heaps and returns one.

We define "minimum" with respect to an
[`Ordering`](https://docs.julialang.org/en/v1/base/sort/#Alternate-orderings)
type parameter, so heaps are parameterized by both the element type and the
ordering.

Heaps in PureFun.jl inherit from the abstract type `PureFun.PFHeap`. The full
interface:

- `push(xs, x)` returns a new heap containing `x` as well as all elements in
  `xs`
- `minimum`
- `popmin`
- `merge`

Heaps iterate in sorted order, so `first(xs::Heap) == minimum(xs)`

If not specified, the ordering for a heap defaults to `Base.Order.Forward`.
Heap constructors are like the constructors for lists and queues, but take the
ordering as an additional optional argument.

## `Pairing.Heap` $\S{5.5}$

The `Pairing.Heap` is very fast, but requires occasional expensive rebalancing
operations to maintain efficient access to the minimum element, and should be
used when the data structure has only a single logical future (see the
discussion in [Queues](@ref) for more information about this concept).
Otherwise, try the [`SkewBinomial.Heap`](@ref) or the
[`BootstrappedSkewBinomial.Heap`](@ref)

```@docs
Pairing.Heap
```

## `SkewBinomial.Heap` $\S{9.3.2}$

```@docs
SkewBinomial.Heap
```

## `BootstrappedSkewBinomial.Heap` $\S{10.2.2}$

```@docs
BootstrappedSkewBinomial.Heap
```

## Function reference

```@docs
PureFun.minimum(::PFHeap)
PureFun.popmin
PureFun.push(::PFHeap, x)
Base.merge(::PFHeap, ::PFHeap)
```

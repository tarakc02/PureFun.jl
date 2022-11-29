```@meta
CurrentModule = PureFun
DocSetup = quote using PureFun end
```

# Queues

Unlike lists, queues iterate in first-in, last-out order. They implement the
following efficiently:

- `push` (to push to the end, analogous to `Base.push!` -- kinda wish they had
  called this `pushlast!` but alas)
- `first`
- `popfirst`

You can use any existing list implementation as a Queue, using the
[`Batched.@deque`](@ref) functor. However, the resulting queue achieves
amortized constant complexity guarantees by batching expensive rebalancing
operations: most operations are fast, but occasionally an operation takes
$\mathcal{O}(n)$ time, and we refer to those as *expensive* operations. In
amortized mutable data structures, expensive operations restore internal
balance, which guarantees you a budget of cheap operations before the next
rebalancing is required. An expensive operation on an immutable data structure
returns a new, balanced data structure, and once again if you restrict your
usage to this new value then the amortized analysis that we used in the
immutable case still applies. But unlike a mutable data structure, a given
instance of an immutable data structure may have multiple *logical futures* --
after calling an expensive operation, we can go back to the same imbalanced
data structure and call an expensive operation again, without having first
benefitted from all the cheap operations in between. The concept is explored in
Chapter 6 ($\S{6.1}$) of *Purely Functional Data Structures*, which introduces
the use of *lazy evaluation* in restoring amortized bounds in persistent
settings.

Use the following queue types if your use-case involves utilizing multiple
logical futures (example: concurrency/multi-threading):

## `Bootstrapped.Queue` $\S{10.1.3}$

`first` takes $\mathcal{O}(1)$ time, while both `push` and `popfirst` take
$\mathcal{O}(\log^{*}{n})$ amortized time, where $\log^{*}$ is the [iterated
logarithm](https://en.wikipedia.org/wiki/Iterated_logarithm), which is
"constant in practice." The amortized bounds extend to settings that require
persistence, this is achieved via disciplined use of [*lazy
evaluation*](https://en.wikipedia.org/wiki/Lazy_evaluation) along with
[memoization](https://en.wikipedia.org/wiki/Memoization)

## `RealTime.Queue` $\S{7.2}$

All operations are worst-case $\mathcal{O}(1)$. These queues make heavy use of
lazy evaluation. Due to the overheads associated with lazy evaluation, the
`PureFun.RealTime.Queue` is slower on average than others, but can still be
useful in settings (such as interactive user-interfaces) where bounded
worst-case performance is more important than average performance.

## `HoodMelville.Queue` $\S{8.2.1}$

```@docs
HoodMelville.Queue
```


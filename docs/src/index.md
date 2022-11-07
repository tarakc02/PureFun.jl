# Purely Functional Data Structures, in Julia

```@meta
CurrentModule = PureFun
DocSetup = quote using PureFun end
```

Wherein [I](https://tarakc02.github.io/) work my way through the book [*Purely
Functional Data
Structures*](https://www.goodreads.com/book/show/594288.Purely_Functional_Data_Structures),
but in [Julia](https://docs.julialang.org/en/v1/) instead of ML/haskell

# What is a persistent data structure?

Consider the following bit of code:

```@repl
x = 42
y = x
y += 1
x
```

Compare to the similar looking code:

```@repl
x = [1,2,3]
y = x
push!(y, 4)
x
```

In the first example, changing the value of `y` did not affect the value of
`x`. However, in the second, I was able to change the contents of `x` without
re-assigning it directly! This can lead to unexpected program behavior: any
time you pass your object as an argument to a function, you can't know for sure
if the called function had the side effect of changing the contents of your
object. A workaround when you want to avoid that possibility is [defensive
copying](http://www.javapractices.com/topic/TopicAction.do?Id=15). If we're
writing multiple small functions [as recommended in the Julia
docs](https://docs.julialang.org/en/v1/manual/performance-tips/#Break-functions-into-multiple-definitions), this can get expensive.

Julia's base arrays, sets, and dictionaries are all mutable. This package
provides data structures that are immutable, so they can be treated as values.

```@repl
using PureFun
x = PureFun.Linked.List(1:3)
y = x
y = pushfirst(y, 4)
x
```

# Overall design

PureFun.jl provides a bunch of different container types, each has an empty
constructor to create a new empty container of that type, and a constructor
that takes an iterable. All of the collection types satisfy the [iteration
interface](https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-iteration)
and can be used in loops, with
[iterators](https://docs.julialang.org/en/v1/base/iterators/), etc. There are
several [functors](https://ocaml.org/docs/functors) that allow you to create
more complicated container types from simpler container types.

Whenever an immutable method has a mutating analogue in `Base`, the immutable
version of the function has the same name as the mutating one without the `!`.
For example, `push` is a non-mutating version of
[`push!`](https://docs.julialang.org/en/v1/base/collections/#Base.push!),
instead of modifying its input argument it returns a new collection with an
element added.

Examples follow.

## Lists

Provide efficient access to the front element, and can efficiently add and
remove elements from the front. Sometimes also called a "stack." Primary
operations:

- `first(xs)`: get the first element of `xs`
- `popfirst(xs)`: returns a new list that looks like `xs` but with the first
  element removed
- `pushfirst(xs, x)`: returns a new list with `x` added to the front of `xs`.
  The infix operator `⇀` (pronounced `\rightharpoonup`) is often more
  convenient. Note that it is right-associative, so

```
x ⇀ y ⇀ zs
```

is equivalent to

```
pushfirst(pushfirst(zs, y), x)
```


Additionally, PureFun.jl implements default implementations of a variety of
[Abstract
Vector](https://docs.julialang.org/en/v1/base/arrays/#Base.AbstractVector)-like
methods for list types, though they are not necessarily efficient. All of these
functions have similar meanings to their mutating (with a `!` at the end of the
function name) counterparts in `Base`.

- `reverse`
- `insert`
- `getindex` (`xs[i]` to get the i-th element of `xs`)
- `setindex` (help wanted: nice syntax for non-mutating `setindex`)
- `append` (use the infix notation `xs ⧺ ys` to append `ys` to the end of `xs`)

Lists iterate in
[LIFO](https://en.wikipedia.org/wiki/Stack_(abstract_data_type)) order, and
work with a variety of built-in [higher-order
functions](https://en.wikipedia.org/wiki/Higher-order_function):

- eager versions of `map`,  `filter`, `accumulate`
- `(map)foldl`, `(map)foldr`, `(map)reduce`

There are several different implementations of lists, optimized for different
use-cases. All of the list implementations in PureFun.jl inherit from the
abstract type `PureFun.PFList`. Complexities presented below are worst-case,
unless stated otherwise.

### `PureFun.Linked.List` ($\S{2.1}$)

This is the simplest of the list types, and the fastest for the primary
operations, which are all $\mathcal{O}(1)$.

### `PureFun.RandomAccess.List` ($\S{9.3.1}$)

Adds efficient ($\mathcal{O}(\log{}n)$) indexing (`getindex` and `setindex`)
operations to the $\mathcal{O}(1)$ primary operations. The implementation
stores elements in complete binary trees representing digits in the [skew
binary number system](https://en.wikipedia.org/wiki/Skew_binary_number_system),
as described in [this blog
post](http://arh68.com/software/2015/05/19/skew-binary-random-access-lists.html).

```@repl
using PureFun
l = PureFun.RandomAccess.List(1:10)
l[7]
```

### `PureFun.Catenable.List` ($\S{10.2.1}$)

Time complexity for `popfirst` and `pushfirst` are amortized $\mathcal{O}(1)$
rather than worst-case. `append` (`⧺`) also takes amortized constant time.

```@repl
using PureFun
l1 = PureFun.Catenable.List(1:3)
l2 = PureFun.Catenable.List(4:5)
l1 ⧺ l2
```

### `PureFun.VectorCopy.List`

This is a wrapper around `Base.Vector` with copy-on-write semantics.
`pushfirst` is $\mathcal{O}(n)$, but iteration and indexing are very fast.
Useful for small lists, or for lists that are traversed frequently relative to
how often they are modified.

### The `Chunky.@list` functor: CPU-cache friendly lists

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
`PureFun.Contiguous`:

- `Contiguous.StaticChunk{N}`: Backed by `StaticArrays.SVector`
- `Contiguous.VectorChunk{N}`: Backed by `Base.Vector`

```@repl
using PureFun
using PureFun: Chunky, Linked, Contiguous, RandomAccess
Chunky.@list ChunkyList Linked.List Contiguous.StaticChunk{8}
Chunky.@list ChunkyRandomAccessList RandomAccess.List Contiguous.VectorChunk{16}
hw = "hello" ⇀ "world" ⇀ ChunkyList{String}()
popfirst(hw)
xs = ChunkyRandomAccessList(1:100)
-999 ⇀ xs
```

### Double-ended Queues: `PureFun.Batched.@deque` $\S{5.2}$, excercise 5.1

Deques are like lists but with symmetric efficient operations on the front
(`pushfirst`, `popfirst`, `first`) and the back (`push`, `pop`, `last`). The
`Batched.@deque` functor takes any existing list implementation, and makes it
double-ended. The resulting deque will maintain the advantages of the
underlying list type. For example, here we create a deque with efficient
index-based access:

```@repl
using PureFun, PureFun.Batched, PureFun.RandomAccess
Batched.@deque Deque RandomAccess.List

data = Deque(1:1_000_000)
first(data)
last(data)
popfirst(data)
pop(data) |> last
pushfirst(data, 13) |> first
push(data, -1) |> last
data[99_999]
```

`pushfirst`, `popfirst`, `push`, and `pop` are all *amortized*
$\mathcal{O}(1)$ rather than worst-case.

## Queues

Unlike lists, queues iterate in first-in, last-out order. They implement the
following efficiently:

- `push` (to push to the end, analogous to `Base.push!` -- kinda wish they had
  called this `pushlast!` but alas)
- `first`
- `popfirst`

You can use any existing list implementation as a Queue, using the `@deque`
functor. However, the resulting queue achieves amortized constant complexity
guarantees by batching expensive rebalancing operations: most operations are
fast, but occasionally an operation takes $\mathcal{O}(n)$ time, and we refer
to those as *expensive* operations. In amortized mutable data structures,
expensive operations restore internal balance, which guarantees you a budget of
cheap operations before the next rebalancing is required. An expensive
operation on an immutable data structure returns a new, balanced data
structure, and once again if you restrict your usage to this new value then the
amortized analysis that we used in the immutable case still applies. But unlike
a mutable data structure, a given instance of an immutable data structure may
have multiple *logical futures* -- after calling an expensive operation, we can
go back to the same imbalanced data structure and call an expensive operation
again, without having first benefitted from all the cheap operations in
between. The concept is explored in Chapter 6 ($\S{6.1}$) of *Purely Functional
Data Structures*, which introduces the use of *lazy evaluation* in restoring
amortized bounds in persistent settings.

Use the following queue types if your use-case involves utilizing multiple
logical futures (example: concurrency/multi-threading):

### `PureFun.Bootstrapped.Queue` $\S{10.1.3}$

`first` takes $\mathcal{O}(1)$ time, while both `push` and `popfirst` take
$\mathcal{O}(\log^{*}{n})$ amortized time, where $\log^{*}$ is the [iterated
logarithm](https://en.wikipedia.org/wiki/Iterated_logarithm), which is
"constant in practice." The amortized bounds extend to settings that require
persistence, this is achieved via disciplined use of [*lazy
evaluation*](https://en.wikipedia.org/wiki/Lazy_evaluation) along with
[memoization](https://en.wikipedia.org/wiki/Memoization)

### `PureFun.RealTime.Queue` $\S{7.2}$

All operations are worst-case $\mathcal{O}(1)$. These queues make heavy use of
lazy evaluation. Due to the overheads associated with lazy evaluation, the
`PureFun.RealTime.Queue` is slower on average than others, but can still be
useful in settings (such as interactive user-interfaces) where bounded
worst-case performance is more important than average performance.

### `PureFun.HoodMelville.Queue` $\S{8.2.1}$

Once again, these queues require worst-case constant time for all 3 queue
operations. Unlike the `PureFun.RealTime.Queue`, the Hood-Melville queue does
not use lazy evaluation, as it more explicitly schedules incremental work
during each operation, smoothing out the costs of rebalancing across cheap
operations. Since this requires doing rebalancing work before it becomes
necessary, the Hood-Melville queues can end up doing unnecessary work, leading
to higher on-average overheads. Once again, use when worst-case performance is
more important than average performance.

## Heaps

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
- `delete_min`

Heaps iterate in sorted order.

If not specified, the ordering for a heap defaults to `Base.Order.Forward`.
Heap constructors are like the constructors for lists and queues, but take the
ordering as an additional optional argument.

### `PureFun.Pairing.Heap` $\S{5.5}

Pairing heaps:

> ... are one of those data structures that drive theoreticians crazy. On the
> one hand, pairing heaps are simple to implement and perform extremely well in
> practice. On the other hand, they have resisted analysis for over ten years!

`push`, `merge`, and `minimum` all run in $\mathcal{O}(1)$ worst-case time.
`delete_min`, however, can take $\mathcal{O}(n)$ time in the worst-case.
However, it has been proven that the amortized time required by `delete_min` is
no worse than $\mathcal{O}(\log{}n)$, and there is an open conjecture that it
is in fact $\mathcal{O}(1)$. The amortized bounds here do *not* apply in
persistent settings.

### `PureFun.SkewHeap.Heap` $\S{9.3.2}$

## PFSet

Implemented by:

- `PureFun.RedBlack.RBSet` (supports all operations in log2(n) time)
- `PureFun.RedBlack.RBSet` also supports `delete`, `delete_min`, and
  `delete_max`, and iteration order is determined by an
  [`Ordering`](https://docs.julialang.org/en/v1/base/sort/#Alternate-orderings)
  type parameter

Supports:

- `push`
- `in`, `∈`

## PFDict

Implemented by:

- `PureFun.RedBlack.RBDict` (supports all operations in log2(n) time)

Supports:

- `setindex`, `getindex`
- `PureFun.RedBlack.RBDict` also supports `delete`, `delete_min`, and
  `delete_max`, and iteration order is determined by an
  [`Ordering`](https://docs.julialang.org/en/v1/base/sort/#Alternate-orderings)
  type parameter

## PFHeap

Implemented by:

- `PureFun.Pairing.Heap`: 
- `PureFun.SkewHeap.Heap`: 
- `PureFun.FastMerging.Heap`:


# See also

- [FunctionalCollections.jl](https://github.com/JuliaCollections/FunctionalCollections.jl)
- [Lazy.jl](https://github.com/MikeInnes/Lazy.jl)
- [Air.jl](https://github.com/noahbenson/Air.jl)

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
provides data strucutres that are immutable, so they can be treated as values.

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

- `first(xs)`: get the first element of `xs`
- `popfirst(xs)`: returns a new list that looks like `xs` but with the first
  element removed

Additionally, PureFun.jl implements default implementations of a variety of
[Abstract
Vector](https://docs.julialang.org/en/v1/base/arrays/#Base.AbstractVector)-like
methods for types that inherit from `PureFun.PFList`, though they are not
necessarily efficient:

- `reverse`
- `insert`
- `getindex` (`xs[i]` to get the i-th element of `xs`)
- `setindex` (help wanted: nice syntax for non-mutating `setindex`)
- `append` (use the infix notation `xs ⧺ ys` to append `ys` to the end of `xs`)
- `map`, `reduce`/`mapreduce`, `filter`

### `PureFun.Linked.List` ($\S{2.1}$)

This is the simplest of the list types, and the fastest for the primary
operations, which are all $\mathcal{O}(1)$.

### `PureFun.RandomAccess.List` ($\S{9.3.1}$)

Adds efficient ($\mathcal{O}(\log{}n)$) indexing (`getindex` and `setindex`)
operations, and an optimized `mapreduce` implementation. The implementation
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
`pushfirst` is $\mathcal{O}(n), but iteration and indexing are very fast.
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

### Double-ended Queues: the `PureFun.Batched.@deque` functor

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

Implemented by:

- `PureFun.Linked.List`
- `PureFun.RandomAccess.List`: fast access to arbitrary elements, compared to
  regular linked lists which take linear time to access elements
- `PureFun.Catenable.List`: fast catenation (appending) of lists, which takes
  O(n) time for regular linked lists

|List Type|`cons`|`head`|`tail`|`append`|`getindex`/`setindex`|`reverse`|
--- | --- | --- | --- | --- | --- | --- |
|`Linked.List`|O(1)|O(1)|O(1)|O(n)|O(n)|O(n)|
|`RandomAccess.List`|O(1)|O(1)|O(1)|O(n)|O(log(n))|O(n)|
|`Catenable.List`|O(1)|O(1)|O(1)|O(1)|O(n)|O(n)|

All implentations support these operations in constant time:

- `cons` a new item to the front (alias: `pushfirst`)
- `head` retrieves the item at the front
- `tail` returns the collection without the front element

All `PFLists` also implement the following operations, which may be slow:

- `append`, or `⧺`: appends two lists. Fast (constant time) for
  `PureFun.Catenable.List`
- `getindex` for array-like indexing. This is fast (log(n)) for
  `PureFun.RandomAccess.List`
- `setindex`: for changing the value at an index. Fast for random-access lists
- `reverse`

## PFQueue

Implemented by:

- `PureFun.Batched.Queue`: supports all operations in amortized constant time.
  However, if the queue is used persistently, the time to get the `tail` can
  devolve to the worst-case, which is linear
- `PureFun.Bootstrapped.Queue`: all operations in amortized constant time, and
  the amortized bounds extend to persistent use (!).
- `PureFun.RealTime.Queue`: worst-case constant time operations (but with a
  higher overhead than the other two).

Operations:

- `snoc` a new item to the back of the queue (alias: `push`)
- `head` get the item at the front of the queue
- `tail` returns the collection without the first item

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

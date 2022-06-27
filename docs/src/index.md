# Purely Functional Data Structures, in Julia

```@meta
CurrentModule = PureFun
DocSetup = quote using PureFun end
```

Wherein [I](https://tarakc02.github.io/) work my way through the book [*Purely
Functional Data
Structures*](https://www.goodreads.com/book/show/594288.Purely_Functional_Data_Structures),
but in [Julia](https://docs.julialang.org/en/v1/) instead of ML.

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
re-assigning it directly!

Julia's base arrays, sets, and dictionaries are all mutable. This package
provides data strucutres that are immutable, so they can be treated as values
like in the first example:

```@repl
using PureFun
x = PureFun.Linked.List(1:3)
y = x
y = cons(4, y)
x
```

# APIs

## PFList

AKA linked lists, or stacks.

Implemented by:

- `PureFun.Linked.List`
- `PureFun.RandomAccess.List`: fast access to arbitrary elements, compared to
  regular linked lists which take linear time to access elements
- `PureFun.Catenable.List`: fast catenation (appending) of lists, which takes
  O(n) time for regular linked lists

All implentations support these operations in constant time:

- `cons` a new item to the front (alias: `push`)
- `head` retrieves the item at the front (alias: `first`)
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

- `snoc` a new item to the back of the queue
- `head` get the item at the front of the queue
- `tail` returns the collection without the first item

## PFSet

Implemented by:

- `PureFun.RedBlack.Set` (supports all operations in log2(n) time)

Supports:

- `insert`
- `in`, `∈`

## PFDict

Implemented by:

- `PureFun.RedBlack.Dict` (supports all operations in log2(n) time)

Supports:

- `setindex`, `getindex`, `push`, `insert`

## PFHeap

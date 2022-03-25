PureFun.jl
============

Data structures from the book *Purely Functional Data Structures*, implemented
in Julia.

# APIs

## PFList

AKA linked lists, or stacks.

Implemented by:

- `PureFun.Lists.Linked.List`
- `PureFun.Lists.SkewBinaryRAL.RAList`

All implentations support these operations in constant time:

- `push` a new item to the front (alias: `cons`)
- `first` retrieves the item at the front
- `tail` returns the collection without the front element

All `PFLists` also implement the following operations:

- `append`, or `⧺`: appends two lists
- `getindex` for array-like indexing. This is fast (log(n)) for
  `SkewBinaryRAL.RAList`, and slow (linear) for `Linked.List`
- `reverse`

## PFQueue

Implemented by:

- `PureFun.Queues.Batched.Queue`: supports all operations in amortized constant
  time. However, if the queue is used persistently, the time to get the `tail`
  can devolve to the worst-case, which is linear
- `PureFun.Queues.Bootstrapped.Queue`: all operations in amortized constant
  time, and the amortized bounds extend to persistent use (!).
- `PureFun.Queues.RealTime.Queue`: worst-case constant time operations (but
  with a higher overhead than the other two).

Operations:

- `push` a new item to the back of the queue (alias: `snoc`)
- `first` get the item at the front of the queue
- `tail` returns the collection without the first item

## PFSet

Implemented by:

- `PureFun.RedBlack.Set` (supports all operations in log2(n) time)

Supports:

- `insert`
- `in`

## PFDict

Implemented by:

- `PureFun.RedBlack.Dict` (supports all operations in log2(n) time)

Supports:

- `setindex`, `getindex`, `push`, `insert`

## PFHeap

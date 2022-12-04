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
x = 42;
y = x;
y += 1
x
```

Compare to the similar looking code:

```@repl
x = [1,2,3];
y = x;
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
x = PureFun.Linked.List(1:3);
y = x;
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

- [Lists](@ref): insert/remove from the front of the list, get the element at
  the front of the lists, and iterate inserted elements in
  [LIFO](https://en.wikipedia.org/wiki/Stack_(abstract_data_type)) order

- [Queues](@ref): insert at the end, remove from the front, iterate in
  [FIFO](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics)) order

- [Heaps](@ref): insert elements, remove elements, retrieve the minimum, and
  iterate in sorted order (wrt an
  [`Ordering`](https://docs.julialang.org/en/v1/base/sort/#Alternate-orderings))

- [Dictionaries](@ref): associate keys with values

- [Sets](@ref): insert keys, test for membership, various set operations
  including `intersect` and `union`

# Customizable data structures: Batched.@deque, Tries.@trie, Chunky.@list

These use generic design strategies to produce more powerful data structures
from simpler ones.

[`PureFun.Batched.@deque`](@ref) takes a list implementation and adds efficient access
(push/pop/last) to the rear of the list, making it into a double-ended queue.
The resulting deque maintains the advantages of the list used to create it, so
for example a deque made from [`PureFun.RandomAccess.List`](@ref) will maintain
fast indexing (get/set index) operations.

[`PureFun.Chunky.@list`](@ref) takes any list implementation, and uses it to
store chunks of elements rather than single elements, in order to improve
iteration speed.

[`PureFun.Tries.@trie`](@ref) builds efficient dictionaries for complex key
types by chaining together dictionaries of simpler keys.

# `PureFun.Contiguous`: small size optimizations

Tries and chunky lists assume the availability of efficient small collections
that can be linked together to build general purpose collections. The
[`PureFun.Contiguous`](@ref) module provides a variety of performant data
structures that make use of [data
locality](https://gameprogrammingpatterns.com/data-locality.html)

# See also

- [FunctionalCollections.jl](https://github.com/JuliaCollections/FunctionalCollections.jl)
- [Lazy.jl](https://github.com/MikeInnes/Lazy.jl)
- [MLStyle.jl](https://thautwarm.github.io/MLStyle.jl/latest/index.html)
- [Air.jl](https://github.com/noahbenson/Air.jl)

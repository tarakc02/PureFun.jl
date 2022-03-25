# Purely Functional Data Structures, in Julia

Wherein [I](https://tarakc02.github.io/) work my way through the book [*Purely
Functional Data
Structures*](https://www.goodreads.com/book/show/594288.Purely_Functional_Data_Structures),
but in [Julia](https://docs.julialang.org/en/v1/) instead of ML.

## Some core concepts

### Data Structure

A data structure is a type of container for data, for example arrays and
dictionaries are data structures. We characterize a data structure by the
collection of operations that it supports, its
[API](https://en.wikipedia.org/wiki/API). For example a *Stack* is a data
structure that supports `push!` (to add a new data element to the container)
and `pop!` (remove the most recently added element).

Time complexity of each operation.

These abstractions enable higher level abstractions -- for example using a heap
(which gives fast access to the minimum element) for best-first search, or
using a stack to enable backtracking in a maze solving algorithm.

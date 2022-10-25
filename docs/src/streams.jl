#=

# Streams

A number of the data structures in PureFun.jl rely on lazy evaluation and
[lazily evaluated
lists](https://mitpress.mit.edu/sites/default/files/sicp/full-text/sicp/book/node69.html),
which are provided by PureFun.Lazy. Here we look at some toy examples to get a
feel for to use Streams.

=#

using PureFun
using PureFun.Lazy: Stream, @cons

#=

## Basics

"Lazy evaluation" describes a strategy for evaluating expressions, and has two main features:

- The evaluation of the expression is delayed (*suspended*) until its result is
  needed

- The result is cached (*memoized*) the first time the expression is evaluated,
  so that subsequent evaluations become cheap lookups

Streams are lazily evaluated lists, and are described in section 4.2 of the
book:

> Streams (also known as lazy lists) are similar to ordinary lists, except that
> every cell is systematically suspended

=#

integers = Stream(Iterators.countfrom(1))

#=

## Comparison to iterators

Like Streams, Julia's
[iterators](https://docs.julialang.org/en/v1/base/iterators/) are also lazily
evaluated. The main difference is that Streams are memoized, meaning that
values that have been calculated are cached and can be revisited without having
to recalculate them.

Like all of the data structures in PureFun.jl, Streams are iterators
themselves, and calling a function from `Base.Iterators` on a Stream works as
expected. Calling `Stream` on an iterator, on the other hand, is kind of like a
lazy `collect`, it materializes computed values as they are iterated out. We
can use the two together to efficiently chain together operations:

=#

using Base.Iterators: zip, drop, take
const accumulate, filter, map = Iterators.accumulate, Iterators.filter, Iterators.map

foo = map(x -> 2x, accumulate(+, filter(isodd, integers))) |> Stream
bar = zip(foo, drop(foo, 1)) |> Stream

collect(take(bar, 7))

bar[2000]

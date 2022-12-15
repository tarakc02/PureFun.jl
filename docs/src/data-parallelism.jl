#=

# Data parallelism

We'll look at two examples of using [data
parallelism](https://juliafolds.github.io/data-parallelism/) to speed up
computation using multiple CPUs

## Example 1: reducing a list

=#

using PureFun, FLoops, BenchmarkTools
using PureFun.Chunky

# We are tasked with optimizing the following function:

sequential(xs) = mapreduce(round ∘ sin, +, xs);

#=

For any applications that require reducing over an entire collection, it makes
sense to reach for a [`PureFun.Chunky.@list`](@ref):

=#

Chunky.@list(ChunkyRandomAccessList,
             list  = PureFun.RandomAccess.List,
             chunk = PureFun.Contiguous.StaticChunk{8})

#=

We start out by benchmarking the current solution:

```julia
julia> @btime(sequential(xs),
              setup = xs = ChunkyRandomAccessList(rand(Int, 5_000)),
              evals = 10, samples=300);
  107.854 μs (1256 allocations: 58.81 KiB)
```

The lists in PureFun.jl implement the
[`SplittablesBase`](https://juliafolds.github.io/SplittablesBase.jl/stable/)
interface, and as a result can be used with [a variety of parallel
algorithms](https://juliafolds.github.io/data-parallelism/). Here we use
[`Floops.jl`](https://juliafolds.github.io/FLoops.jl/dev/) to parallelize our
reduction:
=#

function parallel(xs)
    @floop for x in xs
        @reduce s += round(sin(x))
    end
    return s
end;

# A quick test to make sure the function works as expected:

test = ChunkyRandomAccessList(rand(Int, 100_000))
@assert sequential(test) == parallel(test)

#=

And indeed, we see a decent speedup:

```julia
julia> @btime(parallel(xs),
              setup = xs = ChunkyRandomAccessList(rand(Int, 5_000)),
              evals = 10, samples = 300)
  53.725 μs (793 allocations: 28.46 KiB)
```

## Example 2: parallel heap sort

=#

using PureFun, Folds, BenchmarkTools
using PureFun.Pairing

# If comparisons are expensive, then constructing a heap can get pretty slow:

xs = rand(Int, 1_000);

#=

```julia
julia> @btime Pairing.Heap($xs, Base.Order.By(sin));
  45.333 μs (2998 allocations: 93.69 KiB)
```

In [How to Think about Parallel Programming:
Not!](https://youtu.be/dPK6t7echuA) Guy Steele describes a useful strategy for
parallel programming:

- from each input construct a *singleton* solution
- merge solutions using an *associative* merge operation

We can use that strategy to construct a heap:

=#

const ∅ = Pairing.Heap{Int}(Base.Order.By(sin))
singleton(x) = push(∅, x)

test_seq = Pairing.Heap(xs, Base.Order.By(sin))
test_par = Folds.mapreduce(singleton, merge, xs, init=∅)
@assert all(test_seq .== test_par)

#=
And once again, we see a decent speedup:

```julia
julia> @btime Folds.mapreduce(singleton, merge, $xs, init=∅);
  18.625 μs (7016 allocations: 221.66 KiB)
```
=#

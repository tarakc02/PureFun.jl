#=
this (loading benchmarktools and then activating the purefun project) is kind
of hacky, but seems to work and lets me keep the benchmark tools dependency
(required just for the benchmarks but not the package itself) separate from the
rest of the package. if i knew what the "[extras]" and "[target]" stuff in the
project.toml mean, maybe that would be a better place. as it is, i'm keeping a
separate project.toml for each of tests, benchmarks, and docs.
=#
using Pkg, BenchmarkTools
Pkg.activate("..")
using PureFun

include("src/bench_queue.jl")
include("src/bench_list.jl")
include("src/bench_heap.jl")

queues  = [PureFun.Queues.Batched.Queue,
           PureFun.Queues.RealTime.Queue,
           PureFun.Queues.Bootstrapped.Queue]

lists   = [PureFun.Lists.Linked.List,
           PureFun.Lists.SkewBinaryRAL.RAList,
           PureFun.Catenable.List]

streams = [PureFun.Lazy.Stream]

heaps   = [PureFun.Heaps.Pairing.Heap, PureFun.RedBlack.RB]

suite = BenchmarkGroup()

for l in lists
    ListBenchmarks.addbm!(suite, l)
end

for q in queues
    QueueBenchmarks.addbm!(suite, q)
end

for h in heaps
    HeapBenchmarks.addbm!(suite, h)
end

tune!(suite)
results = run(suite, verbose=false)

m = median(results)
m = minimum(results)

judge(
      #m[PureFun.Catenable.List],
      m[PureFun.Lists.SkewBinaryRAL.RAList],
      m[PureFun.Lists.Linked.List]
     )

judge(m[PureFun.Queues.Bootstrapped.Queue],
      m[PureFun.Queues.Batched.Queue])

m[PureFun.Queues.RealTime.Queue]
m[PureFun.Queues.Bootstrapped.Queue]
m[PureFun.Queues.Batched.Queue]

m3 = median(results[PureFun.Queues.RealTime.Queue])

ratio(m2, m1)
ratio(m3, m1)
ratio(m2, m3)

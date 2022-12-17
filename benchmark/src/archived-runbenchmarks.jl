#=
this (loading benchmarktools and then activating the purefun project) is kind
of hacky, but seems to work and lets me keep the benchmark tools dependency
(required just for the benchmarks but not the package itself) separate from the
rest of the package. if i knew what the "[extras]" and "[target]" stuff in the
project.toml mean, maybe that would be a better place. as it is, i'm keeping a
separate project.toml for each of tests, benchmarks, and docs.
=#
using Pkg, BenchmarkTools
Pkg.devdir("..")
using PureFun

PureFun.Chunky.@list ChunkyList PureFun.Linked.List PureFun.Contiguous.VectorChunk{32}
PureFun.Chunky.@list ChunkyRandomAccessList PureFun.RandomAccess.List PureFun.Contiguous.StaticChunk{8}

PureFun.Batched.@deque LDeque PureFun.Linked.List
PureFun.Batched.@deque RDeque PureFun.RandomAccess.List
PureFun.Batched.@deque CDeque ChunkyList
PureFun.Batched.@deque CRDeque ChunkyRandomAccessList

include("src/bench_queue.jl")
include("src/bench_list.jl")
include("src/bench_heap.jl")

queues  = [LDeque, RDeque, CDeque,
           PureFun.RealTime.Queue,
           PureFun.Bootstrapped.Queue,
           PureFun.HoodMelville.Queue]

lists   = [PureFun.Linked.List,
           LDeque, RDeque, CDeque, CRDeque,
           ChunkyList, ChunkyRandomAccessList,
           PureFun.RandomAccess.List,
           PureFun.VectorCopy.List,
           PureFun.Catenable.List
          ]

streams = [PureFun.Lazy.Stream]

heaps   = [PureFun.Pairing.Heap,
           PureFun.SkewBinomial.Heap,
           PureFun.BootstrappedSkewBinomial.Heap]

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
println(m)

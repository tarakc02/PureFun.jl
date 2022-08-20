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

include("src/bench_queue.jl")
include("src/bench_list.jl")
include("src/bench_heap.jl")

queues  = [PureFun.Batched.Queue,
           PureFun.RealTime.Queue,
           PureFun.Bootstrapped.Queue]

lists   = [PureFun.Linked.List,
           PureFun.Chunky.List{8},
           PureFun.Chunky.List{PureFun.RandomAcess.List, 8}
           PureFun.RandomAccess.List,
           PureFun.VectorCopy.List,
           PureFun.Catenable.List
          ]

streams = [PureFun.Lazy.Stream]

heaps   = [PureFun.Pairing.Heap, PureFun.SkewHeap.Heap, PureFun.FastMerging.Heap]

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
#m = minimum(results)
#
#judge(
#      #m[PureFun.Catenable.List],
#      m[PureFun.Unrolled.List{8}], m[PureFun.Unrolled.List{32}],
#      #m[PureFun.Unrolled.List{8}],
#      m[PureFun.Unrolled.List{32}],
#      #m[PureFun.RandomAccess.List],
#      #m[PureFun.VectorCopy.List],
#      m[PureFun.Linked.List]
#     )
#
#judge(m[PureFun.SkewHeap.Heap], m[PureFun.Pairing.Heap])
#judge(m[PureFun.FastMerging.Heap], m[PureFun.Pairing.Heap])
#judge(m[PureFun.FastMerging.Heap], m[PureFun.SkewHeap.Heap])
#
#judge(m[PureFun.Bootstrapped.Queue],
#      m[PureFun.Batched.Queue])
#
#m[PureFun.RealTime.Queue]
#m[PureFun.Bootstrapped.Queue]
#m[PureFun.Batched.Queue]
#
#m3 = median(results[PureFun.RealTime.Queue])
#
#ratio(m2, m1)
#ratio(m3, m1)
#ratio(m2, m3)
#
#
#ref = rand(Int, 512)
#
#@btime l1 = PureFun.Lists.Linked.List($ref)
#@btime l2 = PureFun.DenseLinkedList.PackedList{8}($ref)
#
#l1 = PureFun.Lists.Linked.List(ref)
#l2 = PureFun.DenseLinkedList.PackedList{8}(ref)
#l3 = collect(ref)
#
#@btime minimum($l1)
#@btime minimum($l2)
#@btime minimum($l3)

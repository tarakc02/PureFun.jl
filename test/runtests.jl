using PureFun
using Test

@test [] == detect_ambiguities(Core, PureFun)
@test [] == detect_ambiguities(Base, PureFun)

include("src/queue-tests.jl")
include("src/list-tests.jl")
include("src/stream-tests.jl")
include("src/heap-tests.jl")
include("src/dict-tests.jl")
include("src/set-tests.jl")

queues  = [PureFun.Batched.Queue,
           PureFun.RealTime.Queue,
           PureFun.Bootstrapped.Queue,
           PureFun.HoodMelville.Queue]

lists   = [PureFun.Linked.List,
           PureFun.Chunky.chunky(8),
           PureFun.Chunky.chunky(8, PureFun.RandomAccess.List),
           PureFun.Chunky.chunky(8, PureFun.Catenable.List),
           PureFun.RandomAccess.List,
           PureFun.Catenable.List,
           PureFun.VectorCopy.List]

streams = [PureFun.Lazy.Stream]

heaps   = [PureFun.Pairing.Heap, PureFun.SkewHeap.Heap, PureFun.FastMerging.Heap]

PureFun.Tries.@Trie LTrie PureFun.AList.mapof(PureFun.Linked.List)
PureFun.Tries.@Trie RBTrie PureFun.RedBlack.RBDict{Base.Order.ForwardOrdering}

dicts = [PureFun.RedBlack.RBDict,
         PureFun.AList.mapof(PureFun.Linked.List),
         PureFun.AList.mapof(PureFun.VectorCopy.List),
         LTrie, RBTrie,
         PureFun.HashTable.HashMap16]

sets = [PureFun.RedBlack.RBSet]

for q in queues
    println(); println(q)
    QueueTests.test(q)
end

for l in lists
    println(); println(l)
    ListTests.test(l)
end

for s in streams
    println(); println(s)
    StreamTests.test(s)
end

for h in heaps
    println(); println(h)
    HeapTests.test(h)
end

for d in dicts
    println(); println(d)
    DictTests.test(d)
end

for s in sets
    println(); println(s)
    SetTests.test(s)
end

include("src/redblack-tests.jl")

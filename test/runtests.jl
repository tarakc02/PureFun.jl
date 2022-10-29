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

PureFun.Chunky.@list ChunkyList PureFun.Linked.List PureFun.Contiguous.StaticChunk{7}
PureFun.Chunky.@list ChunkyRandomAccessList PureFun.RandomAccess.List PureFun.Contiguous.VectorChunk{3}
PureFun.Chunky.@list ChunkyCatenableList PureFun.Catenable.List PureFun.Contiguous.StaticChunk{17}
#ChunkyList = PureFun.Chunky.chunky(7)
#ChunkyRandomAccessList = PureFun.Chunky.chunky(7, PureFun.RandomAccess.List)
#ChunkyCatenableList = PureFun.Chunky.chunky(7, PureFun.Catenable.List)

PureFun.Batched.@deque LDeque PureFun.Linked.List
PureFun.Batched.@deque RDeque PureFun.RandomAccess.List
PureFun.Batched.@deque CDeque ChunkyList

queues  = [LDeque, RDeque, CDeque,
           PureFun.RealTime.Queue,
           PureFun.Bootstrapped.Queue,
           PureFun.HoodMelville.Queue]

lists   = [PureFun.Linked.List,
           ChunkyList, ChunkyRandomAccessList, ChunkyCatenableList,
           PureFun.RandomAccess.List,
           PureFun.Catenable.List,
           PureFun.VectorCopy.List,
           LDeque, RDeque, CDeque]

streams = [PureFun.Lazy.Stream]

heaps   = [PureFun.Pairing.Heap, PureFun.SkewHeap.Heap, PureFun.FastMerging.Heap]

PureFun.Tries.@Trie LTrie PureFun.Association.list(PureFun.Linked.List)
PureFun.Tries.@Trie ChunkyTrie PureFun.Association.list(ChunkyList)
PureFun.Tries.@Trie RBTrie PureFun.RedBlack.RBDict{Base.Order.ForwardOrdering}

dicts = [PureFun.RedBlack.RBDict,
         PureFun.Association.list(PureFun.Linked.List),
         PureFun.Association.list(PureFun.VectorCopy.List),
         LTrie, RBTrie, ChunkyTrie,
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

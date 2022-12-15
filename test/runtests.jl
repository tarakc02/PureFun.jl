using PureFun
using Test
using SplittablesTesting

@test [] == detect_ambiguities(Core, PureFun)
@test [] == detect_ambiguities(Base, PureFun)

include("src/queue-tests.jl")
include("src/list-tests.jl")
include("src/stream-tests.jl")
include("src/heap-tests.jl")
include("src/dict-tests.jl")
include("src/set-tests.jl")

PureFun.Chunky.@list ChunkyList list=PureFun.Linked.List chunk=PureFun.Contiguous.StaticChunk{7}
PureFun.Chunky.@list ChunkyRandomAccessList list=PureFun.RandomAccess.List chunk=PureFun.Contiguous.VectorChunk{3}
PureFun.Chunky.@list ChunkyCatenableList list=PureFun.Catenable.List chunk=PureFun.Contiguous.StaticChunk{17}

PureFun.Batched.@deque LDeque PureFun.Linked.List
PureFun.Batched.@deque RDeque PureFun.RandomAccess.List
PureFun.Batched.@deque CDeque ChunkyList

PureFun.Tries.@trie LTrie edgemap=PureFun.Association.List
PureFun.Tries.@trie RBTrie edgemap=PureFun.RedBlack.RBDict{Base.Order.ForwardOrdering}

PureFun.Tries.@trie(BitMapTrie64,
                    edgemap = PureFun.Contiguous.bitmap(64),
                    keyfunc = PureFun.Contiguous.biterate(6))

PureFun.HashMaps.@hashmap(HAMT,
                          approx   = Main.BitMapTrie64,
                          exact    = PureFun.Association.List,
                          hashfunc = hash ∘ hash)

PureFun.@dict2set LSet LTrie

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

heaps   = [PureFun.Pairing.Heap,
           PureFun.SkewBinomial.Heap,
           PureFun.BootstrappedSkewBinomial.Heap]

dicts = [PureFun.RedBlack.RBDict,
         PureFun.Association.List,
         LTrie, RBTrie,
         HAMT
        ]

sets = [PureFun.RedBlack.RBSet, LSet]

for q in queues
    println(); println(q)
    tmp = q(1:10); tmp2 = empty(tmp);
    QueueTests.test(q)
end

for l in lists
    println(); println(l)
    tmp = l(1:10); tmp2 = empty(tmp);
    ListTests.test(l)
    SplittablesTesting.test_ordered((data = l(1:30), ))
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

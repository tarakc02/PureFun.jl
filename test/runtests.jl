using PureFun
using Test

@test [] == detect_ambiguities(Core, PureFun)
@test [] == detect_ambiguities(Base, PureFun)

include("src/queue-tests.jl")
include("src/list-tests.jl")
include("src/stream-tests.jl")
include("src/heap-tests.jl")

queues  = [PureFun.Queues.Batched.Queue,
           PureFun.Queues.RealTime.Queue]

lists   = [PureFun.Lists.Linked.List]

streams = [PureFun.Lazy.Stream]

heaps   = [PureFun.Heaps.Pairing.Heap]

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

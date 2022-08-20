module PureFun

include("interfaces.jl")

# basic lists, streams
include("lists-streams/list.jl") # PureFun.Linked.List
include("lists-streams/skew-binary-ral.jl") # PureFun.RandomAccess.List
include("lists-streams/stream.jl") # PureFun.Lazy.Stream
include("lists-streams/vector-list.jl")

## queues
include("queues/batchedqueue.jl") # PureFun.Batch
include("queues/realtimequeue.jl")
include("queues/bootstrappedqueue.jl")

## these are also list implementations, but rely on lower-level implementations
## of lists or queues which need to be defined first
#include("lists-streams/ll2.jl")
#include("lists-streams/vector-unrolled-list.jl")

include("lists-streams/catenable-list.jl")
include("lists-streams/chunky.jl")

## Heaps
include("heaps/pairing-heap.jl")
include("heaps/skew-binomial-heap.jl")
include("heaps/bootstrapped-heap.jl")

# redblack (set, dict)
include("redblack/RedBlack.jl")

end

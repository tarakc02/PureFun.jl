module PureFun

include("interfaces.jl")

# basic lists, streams
include("lists-streams/list.jl") # PureFun.Linked.List
include("lists-streams/skew-binary-ral.jl") # PureFun.RandomAccess.List
include("lists-streams/stream.jl") # PureFun.Lazy.Stream
include("lists-streams/vector-list.jl")

include("chunk-types/chunk-interface.jl")
include("lists-streams/chunky2.jl")

## queues
include("queues/batchedqueue2.jl")
include("queues/realtimequeue.jl")
include("queues/bootstrappedqueue.jl")
include("queues/hood-melville.jl")

include("lists-streams/catenable-list.jl")

## Heaps
include("heaps/pairing-heap.jl")
include("heaps/skew-binomial-heap.jl")
include("heaps/bootstrapped-heap.jl")

# redblack (set, dict)
include("redblack/RedBlack.jl")

# dict
include("dicts/association-list.jl")
include("trie/ctrie-param-edgemap.jl")
include("dicts/hashtable.jl")

end

module PureFun

include("interfaces.jl")
include("lists-streams/stream.jl")

module Lists
include("lists-streams/list.jl")
#include("lists-streams/unrolled.jl")
include("lists-streams/skew-binary-ral.jl")
end

module Queues
include("queues/batchedqueue.jl")
include("queues/realtimequeue.jl")
include("queues/bootstrappedqueue.jl")
end

module Heaps
include("heaps/pairing-heap.jl")
end

include("redblack/RedBlack.jl")
include("lists-streams/catenable-list.jl")

end

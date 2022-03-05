module PureFun

include("interfaces.jl")
include("lists-streams/stream.jl")

module Lists
include("lists-streams/list.jl")
include("lists-streams/unrolled.jl")
end

module Queues
include("queues/batchedqueue.jl")
include("queues/realtimequeue.jl")
end

module Heaps
include("heaps/pairing-heap.jl")
end

end

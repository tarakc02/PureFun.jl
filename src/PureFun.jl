module PureFun

include("interfaces.jl")
include("lists-streams/stream.jl")

module Lists
include("lists-streams/list.jl")
end

module Queues
include("queues/batchedqueue.jl")
include("queues/realtimequeue.jl")
end

end

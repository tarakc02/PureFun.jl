module RedBlack

using ...PureFun
#export E, insert, contains, show, length, minimum, maximum

#between, delete_min, iterate

include("basics.jl")
include("accessors.jl")
include("insert.jl")

#include("delmin.jl")
#include("range-ops.jl")
#include("helpers.jl")
#include("iter.jl")

end

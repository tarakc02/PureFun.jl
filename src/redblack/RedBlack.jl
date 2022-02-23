module RedBlack

export E, insert, contains, show, length, minimum, maximum

#between, delete_min, iterate

include("basics.jl")
include("accessors.jl")
include("insert.jl")

#using .RedBlack
#t = E{Int64}()
###NE{:black}(13, t, t)
#b1 = BB(13, t, t, 1, t.order)
#b2 = BB(11, t, b1, 2, t.order)
#typeof(b2)
#t = insert(t, -15)
#contains(t, 1)
#contains(t, -15)
#typeof(Red(15, t, t))
#typeof(Black(15, t, t))


#include("delmin.jl")
#include("range-ops.jl")
#include("helpers.jl")
#include("iter.jl")

end

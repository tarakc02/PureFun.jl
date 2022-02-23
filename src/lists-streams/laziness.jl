#=
# Lazy evaluation

Suspending computation ...
=#

mutable struct Susp
    expr
    cache
end

cache(s::Susp) = s.cache
evalexpr(s::Susp) = s.expr()

is_evaluated(s::Susp) = !isnothing(cache(s))

function setcache!(s::Susp)
    s.cache = evalexpr(s)
end

Susp(expr) = Susp(expr, nothing)

force(l) = l
function force(l::Susp)
    is_evaluated(l) && return cache(l)
    setcache!(l)
end

macro lz(expr)
    suspexpr = quote
        () -> $(esc(expr))
    end
    :(Susp($suspexpr))
end

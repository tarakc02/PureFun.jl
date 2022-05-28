module ListBenchmarks

using ..PureFun
using ..BenchmarkTools

function cons_repeatedly(List, iter)
    out = List{eltype(iter)}()
    for i in iter out = push(out, i) end
    return out
end

function testl(List, iter)
    l = List(iter)
    r = reverse(l)
    return r
    #return r .* 2
end

function addbm!(suite, List)
    suite[List] = BenchmarkGroup()
    suite[List]["cons10"] = @benchmarkable cons(x, xs) setup=(xs=$List(rand(Int, 10)); x=rand(Int))
    suite[List]["cons32"] = @benchmarkable cons(x, xs) setup=(xs=$List(rand(Int, 32)); x=rand(Int))
    suite[List]["fill5k"] = @benchmarkable $List(xs) setup=(xs=rand(Int, 5000))
    suite[List]["iter5k"] = @benchmarkable minimum(xs) setup=(xs=$List(rand(Int, 5000)))
    suite[List]["getindex"] = @benchmarkable xs[4398] setup=(xs=$List(rand(Int, 5000)))
    suite[List]["setindex"] = @benchmarkable Base.setindex(xs, 4398, 0) setup=(xs=$List(rand(Int, 5000)))
end
end

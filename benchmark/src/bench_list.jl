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
    #suite[List]["tail"] = @benchmarkable tail(xs) setup=xs=$List(rand(Int, 128))
    #suite[List]["head"] = @benchmarkable head(xs) setup=xs=$List(rand(Int, 128))
    #suite[List]["reverse"] = @benchmarkable reverse(xs) setup=(xs=$List(rand(Int, 128)))
    #suite[List]["append"] = @benchmarkable xs ⧺ ys setup=(xs=$List(rand(Int, 100)); ys=$(List(rand(Int, 100))))
    #suite[List]["getindex"] = @benchmarkable xs[i] setup=(xs=$List(rand(Int, 256)); i=rand(1:256))
    suite[List]["fill"] = @benchmarkable $List(xs) setup=(xs=rand(Int, 5000))
    suite[List]["empty"] = @benchmarkable minimum(xs) setup=(xs=$List(rand(Int, 5000)))
end
end

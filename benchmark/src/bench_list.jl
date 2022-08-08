module ListBenchmarks

using ..PureFun
using ..BenchmarkTools

function cons_repeatedly(List, iter)
    out = List{eltype(iter)}()
    for i in iter out = cons(i, out) end
    return out
end

function dynamic_cons_tail(List, iter)
    xs = collect(iter)
    l = List(xs[1:100])
    for x in xs[100:end]
        l = (iseven(x) || isempty(l)) ? cons(x, l) : tail(l)
    end
    head(l)
end

function addbm!(suite, List)
    suite[List] = BenchmarkGroup()
    suite[List]["dynamic_cons_tail"] = @benchmarkable dynamic_cons_tail($List, xs) setup=(xs=rand(Int, 500))
    suite[List]["consrepeated_250"] = @benchmarkable cons_repeatedly($List, xs) setup=(xs=rand(Int, 250))
    suite[List]["iter1k"] = @benchmarkable sum(xs) setup=(xs=$List(rand(Int, 1000)))
    suite[List]["getindex"] = @benchmarkable xs[i] setup=(xs=$List(rand(Int, 5000)); i = rand(2500:5000))
    suite[List]["setindex"] = @benchmarkable setindex(xs, 0, i) setup=(xs=$List(rand(Int, 5000)); i = rand(2500:5000))
    suite[List]["append250"] = @benchmarkable xs ⧺ ys setup=(xs=$List(rand(Int, 250)); ys=$List(rand(Int, 250)))
end
end

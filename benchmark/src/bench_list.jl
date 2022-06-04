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
    #suite[List]["cons0"] = @benchmarkable cons(x, xs) setup=(xs=$List{Int}(); x=rand(Int))
    #suite[List]["cons10"] = @benchmarkable cons(x, xs) setup=(xs=$List(rand(Int, 10)); x=rand(Int))
    #suite[List]["cons32"] = @benchmarkable cons(x, xs) setup=(xs=$List(rand(Int, 32)); x=rand(Int))
    #suite[List]["fill5k"] = @benchmarkable $List(xs) setup=(xs=rand(Int, 5000))
    suite[List]["dynamic_cons_tail"] = @benchmarkable dynamic_cons_tail($List, xs) setup=(xs=rand(Int, 1000))
    suite[List]["consrepeated_1k"] = @benchmarkable cons_repeatedly($List, xs) setup=(xs=rand(Int, 1000))
    suite[List]["iter5k"] = @benchmarkable sum(xs) setup=(xs=$List(rand(Int, 5000)))
    suite[List]["getindex"] = @benchmarkable xs[4398] setup=(xs=$List(rand(Int, 5000)))
    suite[List]["setindex"] = @benchmarkable Base.setindex(xs, 4398, 0) setup=(xs=$List(rand(Int, 5000)))
end
end

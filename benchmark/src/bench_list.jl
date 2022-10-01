module ListBenchmarks

using ..PureFun
using ..BenchmarkTools

function cons_repeatedly(lst, iter)
    out = empty(lst)
    for i in iter out = cons(i, out) end
    return out
end

function dynamic_cons_tail(lst, iter)
    xs = collect(iter)
    l = foldr(cons, xs[1:100], init = lst)
    for x in xs[101:end]
        l = (iseven(x) || isempty(l)) ? cons(x, l) : tail(l)
    end
    head(l)
end

function addbm!(suite, List)
    suite[List] = BenchmarkGroup()
    suite[List]["dynamic"] = @benchmarkable dynamic_cons_tail(lst, xs) setup=(xs=rand(Int, 500);lst=$List{Int}())
    suite[List]["consrepeated_250"] = @benchmarkable cons_repeatedly(lst, xs) setup=(xs=rand(Int, 250);lst=$List{Int}())
    suite[List]["construct_from_iter"] = @benchmarkable $List(xs) setup=xs=rand(Int, 250)
    suite[List]["mapreduce1k"] = @benchmarkable mapreduce(x -> x^2, +, xs) setup=(xs=$List(rand(Int, 1000)))
    suite[List]["mapfoldl1k"] = @benchmarkable mapfoldl(x -> x^2, +, xs) setup=(xs=$List(rand(Int, 1000)))
    suite[List]["getindex"] = @benchmarkable xs[i] setup=(xs=$List(rand(Int, 5000)); i = rand(2500:5000))
    suite[List]["setindex"] = @benchmarkable setindex(xs, 0, i) setup=(xs=$List(rand(Int, 5000)); i = rand(2500:5000))
    suite[List]["append250"] = @benchmarkable xs ⧺ ys setup=(xs=$List(rand(Int, 250)); ys=$List(rand(Int, 250)))
    suite[List]["reverse250"] = @benchmarkable reverse(xs) setup=xs=$List(rand(Int, 250))
end
end

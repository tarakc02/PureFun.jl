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
    suite[List]["load-reverse-len512"] = @benchmarkable q=testl($List, iter) setup=iter=rand(Int16, 512)
    suite[List]["load-reverse-len2048"] = @benchmarkable q=testl($List, iter) setup=iter=rand(Int16, 2048)
    suite[List]["cons512"] = @benchmarkable q=cons_repeatedly($List, iter) setup=iter=rand(Int16, 512)
    suite[List]["cons2048"] = @benchmarkable q=cons_repeatedly($List, iter) setup=iter=rand(Int16, 2048)
    suite[List]["sum512"] = @benchmarkable q=sum(x for x in l) setup=l=$List(rand(Int16, 512))
    suite[List]["sum2048"] = @benchmarkable q=sum(x for x in l) setup=l=$List(rand(Int16, 2048))
end

end

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
    suite[List]["len128"] = @benchmarkable q=testl($List, iter) setup=iter=rand(Int16, 128)
    suite[List]["len256"] = @benchmarkable q=testl($List, iter) setup=iter=rand(Int16, 256)
    suite[List]["len512"] = @benchmarkable q=testl($List, iter) setup=iter=rand(Int16, 512)
end


end


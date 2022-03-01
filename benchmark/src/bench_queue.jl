module QueueBenchmarks

using ..PureFun
using ..BenchmarkTools

function snoc_repeatedly(Queue, iter)
    out = Queue{eltype(iter)}()
    for i in iter out = snoc(out, i) end
    return out
end

function qmin(q)
    min = first(q)
    for x in q
        if x < min min = x end
    end
    min
end

function testq(Queue, iter)
    q = snoc_repeatedly(Queue, iter)
    qmin(q)
end

function addbm!(suite, Queue)
    suite[Queue] = BenchmarkGroup()
    suite[Queue]["len128"] = @benchmarkable q=testq($Queue, iter) setup=iter=rand(Int16, 128)
    suite[Queue]["len256"] = @benchmarkable q=testq($Queue, iter) setup=iter=rand(Int16, 256)
    suite[Queue]["len512"] = @benchmarkable q=testq($Queue, iter) setup=iter=rand(Int16, 512)
end


end

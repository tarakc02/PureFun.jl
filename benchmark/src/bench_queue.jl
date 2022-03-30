module QueueBenchmarks

using ..PureFun
using ..BenchmarkTools

function snoc_repeatedly(Queue, iter)
    out = Queue{eltype(iter)}()
    for i in iter out = snoc(out, i) end
    return out
end

fillrandq(Queue, n) = snoc_repeatedly(Queue, rand(Int16, n))

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
    #suite[Queue]["head_256"] = @benchmarkable head(q) setup=q=fillrandq($Queue, 256)
    suite[Queue]["fill256"] = @benchmarkable snoc_repeatedly($Queue, xs) setup=xs=rand(Int, 256)
    #suite[Queue]["snoc_empty"] = @benchmarkable snoc(q, x) setup=(q = $Queue{Int16}(); x = rand(Int16))
    #suite[Queue]["snoc_256"] = @benchmarkable snoc(q, x) setup=(q=fillrandq($Queue, 256); x=rand(Int16))
    suite[Queue]["firsttail"] = @benchmarkable tail(q) setup=q=fillrandq($Queue, 256)
    suite[Queue]["iterate256"] = @benchmarkable minimum(q) setup=q=fillrandq($Queue, 256)
end

end

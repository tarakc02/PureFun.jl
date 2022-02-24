#=
Benchmarks for queue implementations

Basic Queue operations:
- head: get the front element
- snoc: insert an element at the end of the queue
- tail: return a new queue without the first element

Not sure if individual ops are the right level for these benchmarks. So also
including some where we iterate to fill up a queue and then iterate to empty it
again. What else?

=#
module QueueBenchmarks

MODULE = PureFun.RealTimeQueue
Queue = MODULE.Queue

# note: the normal constructor may do something more efficient than this, but
# want to measure performance with lots of `snoc` and `tail` operations
function snoc_repeatedly(iter)
    out = Queue{Int64}()
    for i in iter out = snoc(out, i) end
    return out
end

function qmin(iter)
    q = snoc_repeatedly(iter)
    minsofar = head(q)
    for q0 in q
        if q0 < minsofar minsofar = q0 end
    end
    return minsofar
end

suite = BenchmarkGroup()
suite["in+out"] = BenchmarkGroup()
suite["in+out"]["128"] = @benchmarkable qmin(x) setup=x=rand(Int64, 128)
suite["in+out"]["256"] = @benchmarkable qmin(x) setup=x=rand(Int64, 256)
suite["in+out"]["512"] = @benchmarkable qmin(x) setup=x=rand(Int64, 512)

suite["snoc"] = BenchmarkGroup()
suite["snoc"]["into empty"] = @benchmarkable q=snoc(q0, 14) setup=q0=Queue{Int64}()
suite["snoc"]["into len128"] = @benchmarkable q=snoc(q0, 14) setup=q0=snoc_repeatedly(rand(Int64, 128))
suite["snoc"]["into len256"] = @benchmarkable q=snoc(q0, 14) setup=q0=snoc_repeatedly(rand(Int64, 256))
suite["snoc"]["into len512"] = @benchmarkable q=snoc(q0, 14) setup=q0=snoc_repeatedly(rand(Int64, 512))

suite["head"] = BenchmarkGroup()
suite["head"]["after 1 snoc"] = @benchmarkable head(q) setup = q=snoc(Queue{Int64}(), 97310) evals=1
suite["head"]["after 128 snocs"] = @benchmarkable head(q) setup=(q=snoc_repeatedly(1:128)) evals=1
suite["head"]["after 256 snocs"] = @benchmarkable head(q) setup=(q=snoc_repeatedly(1:256)) evals=1
suite["head"]["after 512 snocs"] = @benchmarkable head(q) setup=(q=snoc_repeatedly(1:512)) evals=1

suite["tail"] = BenchmarkGroup()
suite["tail"]["after 1 snoc"] = @benchmarkable tail(q) setup = q=snoc(Queue{Int64}(), 97310) evals=1
suite["tail"]["after 128 snocs"] = @benchmarkable tail(q) setup=(q=snoc_repeatedly(1:128)) evals=1
suite["tail"]["after 256 snocs"] = @benchmarkable tail(q) setup=(q=snoc_repeatedly(1:256)) evals=1
suite["tail"]["after 512 snocs"] = @benchmarkable tail(q) setup=(q=snoc_repeatedly(1:512)) evals=1

tune!(suite)
results = run(suite, verbose=false)




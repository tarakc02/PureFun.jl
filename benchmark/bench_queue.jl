include("../src/PureFun.jl")

using .PureFun
using .PureFun.Batched
using BenchmarkTools

function snoc_repeatedly(iter)
    out = Batched.Queue{Int64}()
    for i in iter out = snoc(out, i) end
    return out
end

suite = BenchmarkGroup()
suite["snoc"] = BenchmarkGroup()
suite["snoc"]["into empty"] = @benchmarkable q=snoc(q0, 14) setup=q0=Batched.Queue{Int64}()
suite["snoc"]["into len128"] = @benchmarkable q=snoc(q0, 14) setup=q0=snoc_repeatedly(rand(Int64, 128))
suite["snoc"]["into len256"] = @benchmarkable q=snoc(q0, 14) setup=q0=snoc_repeatedly(rand(Int64, 256))
suite["snoc"]["into len512"] = @benchmarkable q=snoc(q0, 14) setup=q0=snoc_repeatedly(rand(Int64, 512))

suite["head"] = BenchmarkGroup()
suite["head"]["after 1 snoc"] = @benchmarkable head(q) setup = q=snoc(Batched.Queue{Int64}(), 97310)
suite["head"]["after 128 snocs"] = @benchmarkable head(q) setup=(q=snoc_repeatedly(1:128))
suite["head"]["after 256 snocs"] = @benchmarkable head(q) setup=(q=snoc_repeatedly(1:256))
suite["head"]["after 512 snocs"] = @benchmarkable head(q) setup=(q=snoc_repeatedly(1:512))

suite["tail"] = BenchmarkGroup()
suite["tail"]["after 1 snoc"] = @benchmarkable tail(q) setup = q=snoc(Batched.Queue{Int64}(), 97310)
suite["tail"]["after 128 snocs"] = @benchmarkable tail(q) setup=(q=snoc_repeatedly(1:128))
suite["tail"]["after 256 snocs"] = @benchmarkable tail(q) setup=(q=snoc_repeatedly(1:256))
suite["tail"]["after 512 snocs"] = @benchmarkable tail(q) setup=(q=snoc_repeatedly(1:512))

tune!(suite)
results = run(suite, verbose=false)


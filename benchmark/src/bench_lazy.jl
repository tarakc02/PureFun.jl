include("../src/PureFun.jl")

using .PureFun
using .PureFun.Lazy
using .PureFun.Linked
import .PureFun.Lazy.@lz, .PureFun.Lazy.force
using BenchmarkTools

suite = BenchmarkGroup()
#suite["lazy-eval"] = BenchmarkGroup(["lazy+force", "vanilla"])
r = rand(100);
integers_from(n) = @cons(Int64, n, integers_from(n+1))
suite["lazy-eval"] = BenchmarkGroup()
suite["lazy-eval"]["suspend"] = @benchmarkable l = @lz sum($r)
suite["lazy-eval"]["lz+force"] = @benchmarkable (l = @lz sum($r); force(l)) 
suite["lazy-eval"]["first-force"] = @benchmarkable force(l) setup=(l = @lz sum($r)) 
suite["lazy-eval"]["force-again"] = @benchmarkable force(l) setup=(l = @lz sum($r); force(l)) 
suite["lazy-eval"]["force-third"] = @benchmarkable force(l) setup=(l = @lz sum($r); force(l); force(l)) 
suite["lazy-eval"]["vanilla"] = @benchmarkable sum($r)

suite["forcing calculated stream elements"] = BenchmarkGroup()
suite["forcing calculated stream elements"]["first"] = @benchmarkable head(ints) setup=ints=integers_from(0)
suite["forcing calculated stream elements"]["second"] = @benchmarkable head(tail(ints)) setup=ints=integers_from(0)
suite["forcing calculated stream elements"]["third"] = @benchmarkable head(tail(tail(ints))) setup=(ints=integers_from(0)) 

suite["forcing stream elements"] = BenchmarkGroup()
suite["forcing stream elements"]["first"] = @benchmarkable head(ints) setup=ints=Lazy.Stream(1:10)
suite["forcing stream elements"]["second"] = @benchmarkable head(tail(ints)) setup=ints=Lazy.Stream(1:10)
suite["forcing stream elements"]["third"] = @benchmarkable head(tail(tail(ints))) setup=(ints=Lazy.Stream(1:10))

suite["forcing list elements"] = BenchmarkGroup()
suite["forcing list elements"]["first"] = @benchmarkable head(ints) setup=ints=Linked.List(1:10)
suite["forcing list elements"]["second"] = @benchmarkable head(tail(ints)) setup=ints=Linked.List(1:10)
suite["forcing list elements"]["third"] = @benchmarkable head(tail(tail(ints))) setup=(ints=Linked.List(1:10)) 

tune!(suite, evals=1)
results = run(suite, verbose=false, evals=1)

ratio(median(suite["lazy-eval"]["lz+force"]), median(suite["lazy-eval"]["vanilla"]))


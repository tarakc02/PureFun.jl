module HeapBenchmarks

using ..PureFun
using ..BenchmarkTools

randheap(Heap, n) = Heap(rand(Int16, n))

function fill_and_empty(Heap, iter)
    h = Heap(iter)
    s = Int16(0)
    for el in h s += el end
    return s
end

function fill_and_half_empty(Heap, iter)
    h = Heap(iter)
    for i in 1:div(length(iter),2)
        h = delete_min(h)
    end
    return h
end

function addbm!(suite, Heap)
    suite[Heap] = BenchmarkGroup()
    suite[Heap]["fill_10k"] = @benchmarkable $Heap(x) setup=x=rand(Int16, 10_000)
    suite[Heap]["fill_empty_1k"] = @benchmarkable fill_and_empty($Heap, iter) setup=iter=rand(Int16, 1_000)
    suite[Heap]["ins_empty"] = @benchmarkable push(h, x) setup=(h = $Heap{Int16}(); x = rand(Int16))
    suite[Heap]["ins_10k"] = @benchmarkable push(h, x) setup=(h=randheap($Heap, 10_000); x=rand(Int16))
    suite[Heap]["min_10k"] = @benchmarkable minimum(h) setup=h=randheap($Heap, 10_000)
    suite[Heap]["delmin_10k"] = @benchmarkable delete_min(h) setup=h=randheap($Heap, 10_000)
    suite[Heap]["delmin_half10k"] = @benchmarkable delete_min(h) setup=h=fill_and_half_empty($Heap, rand(Int16, 10_000))
    suite[Heap]["merge1k"] = @benchmarkable merge(h1, h2) setup=(h1=$Heap(rand(Int, 1_000)); h2=$Heap(rand(Int, 1_000)))
end

end

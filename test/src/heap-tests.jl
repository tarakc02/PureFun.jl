module HeapTests

using PureFun
using Test
using Random: shuffle

function test_constructors(Heap)
    @testset "Constructors" begin
        l = Heap{Int64}()
        m = push(l, 4)
        @test l isa Heap
        @test m isa Heap
        @test isempty(l)
        @test !isempty(m)
        @test Heap(1:10) isa Heap
        @test !isempty(Heap(1:10))
    end
end

function test_accessors(Heap)
    @testset "Element Accessors" begin
        l = Heap(shuffle(1:10))
        @test minimum(l) == 1
        @test minimum(delete_min(l)) == 2
        @test minimum(delete_min(delete_min(l))) == 3
        m = delete_min(delete_min(delete_min(delete_min(l))))
    end
end

function test_inorder_iteration(Heap)
    @testset "should iterate in order, regardless of insertion order" begin
        l = Heap(shuffle(1:100))
        @test all(collect(l) .== 1:100)
    end
end

function stress_test(Heap)
    @testset "stress test insert and iterate" begin
        l = Heap(shuffle(1:100_000));
        @test all(l .== 1:100_000)
    end
end

function test(Heap)
    test_constructors(Heap), test_accessors(Heap),
    test_inorder_iteration(Heap), stress_test(Heap)
end

end



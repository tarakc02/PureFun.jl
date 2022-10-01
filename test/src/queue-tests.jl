module QueueTests

using PureFun
using Test

function test_constructors(Queue)
    @testset "Constructors" begin
        q = Queue{Int64}()
        q2 = snoc(q, 4)
        @test q isa Queue
        @test q2 isa Queue
        @test isempty(q)
        @test !isempty(q2)
        @test Queue(1:10) isa Queue
        @test !isempty(Queue(1:10))
    end
end

function test_snoc(Queue)
    @testset "snoc" begin
        q = snoc(Queue{Int64}(), 4)
        @test q isa Queue
        @test !isempty(q)
        @test first(q) == 4
        @test first(snoc(q, 17)) == 4
        @test first(tail(snoc(q, 17))) == 17
    end
end

function stress_test(Queue)
    @testset "stress test snoc and iterate" begin
        l = Queue(1:5_000);
        l2 = Queue{Int}()
        for i in 1:630 l2 = snoc(l2, i) end
        @test all(l .== 1:5_000)
        @test all(l2 .== 1:630)
    end
end

function test_accessors(Queue)
    @testset "Element Accessors (first/tail)" begin
        l = Queue(1:10)
        @test first(l) == 1
        @test first(tail(l)) == 2
        @test first(tail(tail(l))) == 3
    end
end

function test_iterators(Queue)
    @testset "iterate" begin
        l = Queue(1:10)
        @test all([x for x in l] .== 1:10)
    end
end


function test(Queue)
    test_constructors(Queue),
    test_snoc(Queue),
    test_accessors(Queue),
    test_iterators(Queue)
    stress_test(Queue)
end

end

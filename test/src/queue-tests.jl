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

function test_accessors(Queue)
    @testset "Element Accessors (first/tail)" begin
        l = Queue(1:10)
        @test first(l) == 1
        @test first(tail(l)) == 2
        @test first(tail(tail(l))) == 3
    end
end

function test(Queue)
    test_constructors(Queue), test_snoc(Queue), test_accessors(Queue)
end

end

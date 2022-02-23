using .PureFun.Batched

@testset "Batched queues" begin
    @testset "Constructors" begin
        q = Batched.Queue{Int64}()
        q2 = snoc(q, 4)
        @test q isa Batched.Queue
        @test q2 isa Batched.Queue
        @test is_empty(q)
        @test !is_empty(q2)
        @test Batched.Queue(1:10) isa Batched.Queue
        @test !is_empty(Batched.Queue(1:10))
    end

    @testset "snoc" begin
        q = snoc(Batched.Queue{Int64}(), 4)
        @test q isa Batched.Queue
        @test !is_empty(q)
        @test head(q) == 4
        @test head(snoc(q, 17)) == 4
        @test head(tail(snoc(q, 17))) == 17
    end

    @testset "Element Accessors (head/tail)" begin
        l = Batched.Queue(1:10)
        @test head(l) == 1
        @test head(tail(l)) == 2
        @test head(tail(tail(l))) == 3
    end
end


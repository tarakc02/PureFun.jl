# copied liberally from source code for DataStructures.jl
using .PureFun.Linked

@testset "Linked Lists" begin
    @testset "Constructors" begin
        l = Linked.List{Int64}()
        m = cons(4, l)
        @test l isa Linked.List
        @test m isa Linked.List
        @test is_empty(l)
        @test !is_empty(m)
        @test Linked.List(1:10) isa Linked.List
        @test !is_empty(Linked.List(1:10))
    end

    @testset "Element Accessors" begin
        l = Linked.List(1:10)
        @test head(l) == 1
        @test head(tail(l)) == 2
        @test head(tail(tail(l))) == 3
    end

    @testset "Optional methods: reverse, append, length" begin
        l = Linked.List(1:10)
        m = l ⧺ l
        @test !is_empty(l)
        @test length(l) == 10
        @test all(reverse(l) .== 10:-1:1)
        @test length(m) == 20
        @test all(m .== [1:10..., 1:10...])
    end
end

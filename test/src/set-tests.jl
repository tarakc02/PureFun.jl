module SetTests

using PureFun
using Test

function test_constructors(S)
    @testset "Constructors" begin
        l = S{Int64}()
        m = push(l, 14)
        @test l isa S
        @test m isa S
        @test 14 ∈ m
        @test isempty(l)
        @test !isempty(m)
        @test S('a':'z') isa S
        @test !isempty(S(1:100))
    end
end

function test_in(S)
    @testset "in" begin
        rnd = rand(Int, 100)
        s = S(rnd)
        for i in rnd @test i ∈ s end
    end
end

function test(S)
    test_constructors(S), test_in(S)
end

end





module ListTests

using PureFun
using Test

function test_constructors(List)
    @testset "Constructors" begin
        l = List{Int64}()
        m = push(l, 4)
        @test l isa List
        @test m isa List
        @test isempty(l)
        @test !isempty(m)
        @test List(1:10) isa List
        @test !isempty(List(1:10))
    end
end

function test_accessors(List)
    @testset "Element Accessors" begin
        l = List(1:10)
        @test first(l) == 1
        @test first(tail(l)) == 2
        @test first(tail(tail(l))) == 3
    end
end

function test_iterator(List)
    @testset "Iterates in expected order" begin
        l = List(1:10)
        @test all(collect(l) .== 1:10)
    end
end

function test_etc(List)
    @testset "reverse, append, length" begin
        l = List(1:10)
        m = l ⧺ l
        @test !isempty(l)
        @test length(l) == 10
        @test all(reverse(l) .== 10:-1:1)
        @test length(m) == 20
        @test all(m .== [1:10..., 1:10...])
    end
end

function test(List)
    test_constructors(List), test_accessors(List), test_etc(List)
end

end


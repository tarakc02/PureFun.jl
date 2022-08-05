module DictTests

using PureFun
using Test
using Random: shuffle

function test_constructors(D)
    @testset "Constructors" begin
        l = D{Char, Int64}()
        m = setindex(l, 14, 'a')
        @test l isa D
        @test m isa D
        @test isempty(l)
        @test !isempty(m)
        @test D(k => k+1 for k in 'a':'z') isa D
        @test !isempty(D(k => k+1 for k in 'a':'z'))
    end
end

function test_accessors(D)
    @testset "Element Accessors" begin
        l = D(k => k+1 for k in 'a':'z')
        @test l['c'] == 'd'
    end
end

function test(D)
    test_constructors(D), test_accessors(D)
end

end




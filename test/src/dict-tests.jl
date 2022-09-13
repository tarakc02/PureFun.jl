module DictTests

using PureFun
using Test
using Random

function test_constructors(D)
    @testset "Constructors" begin
        l = D{String, Int64}()
        m = setindex(l, 14, "abc")
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
        ks = [randstring(10) for _ in 1:100]
        l = D(k => k for k in ks)
        @test all(key in ks for key in keys(l))
        @test all(key in keys(l) for key in ks)
        @test all(l[k] == k for k in ks)
    end
end

function test(D)
    test_constructors(D), test_accessors(D)
end

end




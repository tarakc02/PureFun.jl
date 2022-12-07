module DictTests

using PureFun
using Test
using Random

function test_constructors(D)
    @testset "Constructors" begin
        l = D{String, Int}()
        dd0 = D{Int, Int}()
        m = setindex(l, 14, "abc")
        dd1 = setindex(dd0, 42, 42)
        @test l isa D
        @test m isa D
        @test dd1 isa D
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

function test_empty(D)
    @testset "empty" begin
        ks = [randstring(10) for _ in 1:100]
        l = D(k => k for k in ks)
        @test isempty(empty(l))
        @test empty(l) isa D
    end
end


function test_etc(D)
    @testset "Edge cases for string keys" begin
        # tries require iterating over the key, can cause issues with
        # variable-length encoded strings if not handled correctly
        d = D{String,Int}()
        d = setindex(d, 0, "bear")
        d = setindex(d, 1, "bees")
        d = setindex(d, 1, "b❤️")
        @test haskey(d, "bear")
        @test haskey(d, "bees")
        @test haskey(d, "b❤️")
    end
end

function test(D)
    test_constructors(D), test_accessors(D), test_etc(D), test_empty(D)
end

end




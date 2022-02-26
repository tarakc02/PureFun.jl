module StreamTests

using PureFun
using PureFun.Lazy
using Test

function test_constructors(Stream)
    @testset "Constructors" begin
        l = Stream{Int64}()
        m = @cons(Int64, 17, l)
        l_10 = Stream(1:10)
        @test l isa Stream
        @test m isa Stream
        @test isempty(l)
        @test !isempty(m)
        @test l_10 isa Stream
        @test !isempty(l_10)
    end

end

function test_accessors(Stream)
    @testset "Element Accessors" begin
        l = Stream(1:10)
        @test first(l) == 1
        @test first(tail(l)) == 2
        @test first(tail(tail(l))) == 3
    end

end

function test(Stream)
    test_constructors(Stream), test_accessors(Stream)
end

end



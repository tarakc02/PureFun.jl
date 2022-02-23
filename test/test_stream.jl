using .PureFun.Lazy
using .PureFun.Lazy: @lz

function testfun(k)
    #println("executing body of testfun")
    sleep(k)
    return rand(Int16)
end

function stest(k)
    x = @lz testfun(k)
    res = [Lazy.force(x) for _ in 1:5]
    return res
end


function ptest(k)
    x = @lz testfun(k)
    res = [(Threads.@spawn Lazy.force($x)) for _ in 1:5]
    return [fetch(r) for r in res]
end


#x = @lz testfun(1)
#Lazy.force(x)
#bloop = ptest(1);
#bloops = stest(1);
#
#
#@benchmark testfun(.2)
#@benchmark ptest(.2)

@testset "Lazy Streams" begin

    @testset "Constructors" begin
        l = Lazy.Stream{Int64}()
        m = @cons(Int64, 17, l)
        l_10 = Lazy.Stream(1:10)
        @test l isa Lazy.Stream
        @test m isa Lazy.Stream
        @test is_empty(l)
        @test !is_empty(m)
        @test l_10 isa Lazy.Stream
        @test !is_empty(l_10)
    end

    @testset "Element Accessors" begin
        l = Lazy.Stream(1:10)
        @test head(l) == 1
        @test head(tail(l)) == 2
        @test head(tail(tail(l))) == 3
    end

    @testset "Functionals (map, filter, accumulate)" begin
        @test true
    end
end

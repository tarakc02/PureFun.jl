module ListTests

using PureFun
using Test

function test_constructors(List)
    @testset "Constructors" begin
        l = List{Int64}()
        empty_iter = List(String[])
        #@test l isa List

        m = pushfirst(l, 4)
        #@test m isa List

        m2 =  cons(4, l)
        #@test m2 isa List

        @test isempty(l)
        @test isempty(empty_iter)
        @test !isempty(m)
        @test !isempty(m2)
        
        @test all(m .== (4,))
        @test all(m2 .== (4,))

        @test !isempty(List(1:10))
        @test all(List(1:10) .== 1:10)
    end
end

function test_accessors(List)
    @testset "Element Accessors" begin
        l = List(1:10)
        @test head(l) == 1
        @test first(tail(l)) == 2
        @test first(tail(tail(l))) == 3
        @test l[5] == 5
        l2 = Base.setindex(l, 99, 3)
        @test l2[3] == 99
        @test all((l[i] for i in 1:10) .== 1:10)
    end
end

function test_iterator(List)
    @testset "Iterates in expected order" begin
        l = List(1:100)
        @test all(l .== 1:100)
    end
end

function stress_test(List)
    @testset "stress test cons, reverse, iterate" begin
        iter = 1:50_000
        l = List(iter)
        r = reverse(l)
        @test all(l .== iter)
        @test all(r .== reverse(iter))
        @test all(tail(r) .== 49_999:-1:1)
    end
end

function test_etc(List)
    @testset "reverse, append, length" begin
        l = List(1:10)
        m = l ⧺ l
        e = empty(l)
        @test !isempty(l)
        @test length(l) == 10
        @test all(reverse(l) .== 10:-1:1)
        @test reverse(e) === e
        @test length(m) == 20
        @test all(m .== [1:10..., 1:10...])
    end
end

function test_functionals(List)
    @testset "map, (map-)reduce, filter" begin
        xs = rand(Int, 100)
        l = List(xs)
        mt = empty(l)
        ct = PureFun.container_type(l)
        @test all(sin.(xs) .== map(sin, l))
        @test PureFun.container_type(map(identity, l)) === ct
        @test isempty(map(identity, mt))
        @test all(filter(iseven, xs) .== filter(iseven, l))
        @test PureFun.container_type(filter(iseven, l)) === ct
        @test isempty(filter(iseven, mt))
        @test mapreduce(x -> x^2, +, xs) == mapreduce(x -> x^2, +, l)
        @test mapreduce(x -> x^2, +, mt, init=0) == 0
        @test sum(xs) == sum(l)
        @test sum(l) != sum(popfirst(l))
        @test sum(popfirst(l)) == sum(xs[2:end])
    end
end

function test(List)
    tmp = List(1:10)
    tmp2 = empty(tmp)

    test_constructors(List),
    test_accessors(List),
    test_iterator(List),
    stress_test(List),
    test_etc(List),
    test_functionals(List)
end

end


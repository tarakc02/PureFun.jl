module ListTests

using PureFun
using Test

function test_constructors(List)
    @testset "Constructors" begin
        l = List{Int64}()
        m = pushfirst(l, 4)
        m2 =  cons(4, l)
        @test l isa List
        @test m isa List
        @test m2 isa List
        @test isempty(l)
        @test !isempty(m)
        @test !isempty(m2)
        @test List(1:10) isa List
        @test !isempty(List(1:10))
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
        @test l[3] == 3
        @test l2[3] == 99
    end
end

function test_iterator(List)
    @testset "Iterates in expected order" begin
        l = List(1:1000)
        @test all(collect(l) .== 1:1000)
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
        @test !isempty(l)
        @test length(l) == 10
        @test all(reverse(l) .== 10:-1:1)
        @test length(m) == 20
        @test all(m .== [1:10..., 1:10...])
    end
end

function test_functionals(List)
    @testset "map, (map-)reduce, filter" begin
        xs = rand(Int, 100)
        l = List(xs)
        @test all(sin.(xs) .== map(sin, l))
        @test all(filter(iseven, xs) .== filter(iseven, l))
        @test mapreduce(x -> x^2, +, xs) == mapreduce(x -> x^2, +, l)
        @test sum(xs) == sum(l)
    end
end

function test(List)
    test_constructors(List),
    test_accessors(List),
    test_iterator(List),
    stress_test(List),
    test_etc(List),
    test_functionals(List)
end

end


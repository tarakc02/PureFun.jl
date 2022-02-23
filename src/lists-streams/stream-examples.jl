include("stream.jl")
#include("laziness.jl")
using .Streams

integers_from(start) = @cons Int64 start integers_from(start + 1)
integers = integers_from(1)
map(x -> 2x, integers)
filter(isodd, integers)

map(x -> 2x, accumulate(+, integers, 0))
accumulate(/, integers, 0)

#=
# Estimating pi
=#
function est_pi(n)
    summands = est_pi(n, 1)
    sums = accumulate(+, summands, 0.0)
    map(x -> 4x, sums)
end

function est_pi(n, one)
    @cons Float64 one/n est_pi(n+2, -one)
end

est_pi(1)

euler_transform(s₀, s₁, s₂) = s₂ - (s₂ - s₁)^2/(s₀ - 2s₁ + s₂)

function euler_transform(stream::Streams.Stream, s₀, s₁)
    s₂ = head(stream)
    @cons(Float64, euler_transform(s₀, s₁, s₂),
          euler_transform(tail(stream), s₁, s₂))
end

function euler_transform(stream::Streams.Stream, s₀)
    s₁ = head(stream)
    euler_transform(tail(stream), s₀, s₁)
end

function euler_transform(s::Streams.Stream)
    s₀ = head(s)
    euler_transform(tail(s), s₀)
end

euler_transform(est_pi(1))
euler_transform(est_pi(1)) |> euler_transform

pis = est_pi(1)
@code_warntype euler_transform(pis)


using BenchmarkTools
@btime filter(isodd, ints) setup = ints=integers_from(0)
@btime isodd(n) setup=n=rand(Int64)
@btime est_pi(1)[3]
@btime head(est_pi(1))
@btime euler_transform(est_pi(1))
@btime head(euler_transform(est_pi(1)))

# 159ns, 1 alloc=896 bytes
@btime sum(rand(Float64, 100))

include("src/laziness.jl")
include("src/cons-list.jl")
using .Lists
using .Lazy

sumrand(n) = sum(rand(Float64, n))
function sumrand_lz(n)
    s = @lz sum(rand(Float64, n))
    force(s)
end

@btime sumrand(n) setup=(n=100)
@btime sumrand_lz(n) setup=(n=100)

function force_one(num)
    s = stream(num)
    Streams.head(s)
end

function get_one(num)
    l = list(num)
    LinkedList.head(l)
end

@btime get_one(1)
@btime force_one(1)


include("list.jl")
using .LinkedList
@btime LinkedList.head(l) setup=(l = LinkedList.list(1:100))
@btime Streams.head(l) setup=(l = stream(1:100))
@btime LinkedList.tail(l) setup=(l = LinkedList.list(1:100))
@btime Streams.tail(l) setup=(l = stream(1:100))
@btime LinkedList.list(1:1000)
@btime Streams.stream(1:10_000)


# 9.4ns 0 allocs
@btime sum(rands) setup=(rands = rand(Float64, 100))

# 7ns, 1 alloc = 32 bytes
@btime @lz Float64 sum(rand(Float64, 100))

# 3-4ns?? seems like a mistake? and 0 allocs
@benchmark force(y) setup = ( y = @lz Float64 sum(rand(Float64, 100)) )

# ~2.7ns, seems like the previous version is grabbing the cached value and not recalculating
@benchmark force(y) setup = (y = @lz Float64 sum(rand(Float64, 100)); force(y))

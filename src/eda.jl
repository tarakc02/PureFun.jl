using PureFun

using PureFun.Linked
using PureFun.Lazy: @lz, Susp
using BenchmarkTools

# orig implementation {{{
struct ReverseLater{T}
    s::Susp
end

ReverseLater(l::Linked.NonEmpty{T}) where T = ReverseLater{T}(@lz reverse(l))

function force(reversal::ReverseLater{T}) where T 
    PureFun.Lazy.force(reversal.s)::Linked.NonEmpty{T}
end

# }}}

# alt {{{

mutable struct RLater{T}
    orig::Union{Nothing,Linked.NonEmpty{T}}
    reversed::Union{Nothing,Linked.NonEmpty{T}}
end

RLater(l::Linked.NonEmpty{T}) where T = RLater{T}(l, nothing)

function force(reversal::RLater{T}) where T
    !isnothing(reversal.reversed) && return reversal.reversed::Linked.NonEmpty{T}
    rv!(reversal)
    return reversal.reversed::Linked.NonEmpty{T}
end

function rv!(rlater::RLater{T}) where T
    rlater.reversed = reverse(rlater.orig::Linked.NonEmpty{T})
    rlater.orig = nothing
end

# }}}

test = Linked.List(1:100)
orig_rl = ReverseLater(test)
force(orig_rl)

new_rl = RLater(test)
force(new_rl)

function check_orig(ll)
    bloop = ReverseLater(ll)
    force(bloop)
end

function check_new(ll)
    bloop = RLater(ll)
    force(bloop)
end

function check_naive(ll)
    reverse(ll)
end

@btime check_orig(xs) setup=xs=Linked.List(rand(Int, 16))
@btime check_new(xs) setup=xs=Linked.List(rand(Int, 16))
@btime check_naive(xs) setup=xs=Linked.List(rand(Int, 16))


function rawsum(xs)
    s = 0.0
    for x in xs
        s += x^2
    end
    s
end

bloop1(xs) = mapfoldl(x -> x^2, +, xs)
bloop2(xs) = mapfoldl(x -> x^2, +, Iterators.flatten(xs.chunks))
_tmp = Iterators.flatten(l.chunks)
which(mapfoldl, Tuple{typeof(x -> x^2), typeof(+), typeof(_tmp)})

@btime rawsum(xs) setup=xs=MyList(rand(Int,100));
@btime rawsum(Iterators.flatten(xs.chunks)) setup=xs=MyList(rand(Int,100));
@btime foldl(+, Iterators.flatten(xs.chunks)) setup=xs=MyList(rand(Int,100));
@btime foldl(+, xs) setup=xs=MyList(rand(Int,100));
@btime bloop1(xs) setup=xs=MyList(rand(Int,100));
@btime bloop2(xs) setup=xs=MyList(rand(Int,100));

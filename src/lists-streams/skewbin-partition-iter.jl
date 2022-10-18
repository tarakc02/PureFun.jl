struct SkewBinary{I}
    it::I
end
skew_binary(x) = SkewBinary(x)

Iterators.reverse(x::SkewBinary) = foldl(pushfirst, x, init=PureFun.Linked.List{eltype(x.it)}())
Base.reverse(x::SkewBinary) = foldl(pushfirst, x, init=PureFun.Linked.List{eltype(x.it)}())

get_next_exponent(x) = Int(floor(log2(x+1)))

"""
    get_next_skewdigit(x)

Returns the first (most significant) digit in the
[skew-binary](https://en.wikipedia.org/wiki/Skew_binary_number_system)
representation of x
"""
function get_next_skewdigit(x)
    ex = get_next_exponent(x)
    cand = 2^ex - 1
    cand > x ? (2^(ex-1) - 1) : cand
end

function Base.iterate(sp::SkewBinary)
    n = sp.it
    ix1 = get_next_skewdigit(n)
    ix1, n-ix1
end

function Base.iterate(sp::SkewBinary, state)
    n = state
    n <= 0 && return nothing
    ix1 = get_next_skewdigit(n)
    ix1, n-ix1
end

skew_binomial_lengths(xs) = reverse(skew_binary(length(xs)))

function buildtree(els, from, to)
    n = to-from+1
    # optimization: unravel the recursion for small trees
    n <= 7 && return smalltree(els, from, to, n)
    pivot = 1+div(n,2)
    l = buildtree(els, from+1, from+pivot-1)
    Node{eltype(els)}(els[from], l, buildtree(els, from+pivot, to))
end

function smalltree(els, from, to, n)
    if n == 1
        Leaf{eltype(els)}(els[from])
    elseif n == 3
        Node{eltype(els)}(els[from],
                          Leaf{eltype(els)}(els[from+1]),
                          Leaf{eltype(els)}(els[to]))
    else
        Node{eltype(els)}(els[from],
                          Node{eltype(els)}(els[from+1],
                               Leaf{eltype(els)}(els[from+2]),
                               Leaf{eltype(els)}(els[from+3])),
                          Node{eltype(els)}(els[from+4],
                               Leaf{eltype(els)}(els[from+5]),
                               Leaf{eltype(els)}(els[to])))
    end
end

function makedigit(els, from , to)
    Digit(to-from+1, buildtree(els, from, to))
end

makelist(xs) = _makelist(collect(xs))
makelist(xs::AbstractRange) = _makelist(xs)
makelist(xs::AbstractString) = _makelist(xs)
function _makelist(xs)
    lens = skew_binomial_lengths(xs)
    starts = cons(1, accumulate(+, lens, init=1))
    ends = accumulate(+, lens)
    ds = (makedigit(xs, from, to) for (from, to) in zip(starts, ends))
    rl = reverse(foldl(pushfirst, ds, init=Linked.List{Digit{eltype(xs)}}()))
    List{eltype(xs)}(rl)
end

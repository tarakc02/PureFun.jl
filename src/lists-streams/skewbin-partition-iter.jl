struct SkewPartitionIterator{I}
    it::I
end
skew_partition(xs) = SkewPartitionIterator(xs)

get_next_digit(len) = Int(floor(log2(len+1)))
function get_next_range(len)
    ex = get_next_digit(len)
    cand = 2^ex - 1
    cand > len ? (2^(ex-1) - 1) : cand
end

function Base.iterate(sp::SkewPartitionIterator)
    n = length(sp.it)
    ix1 = get_next_range(n)
    (1, ix1), (1+ix1, n-ix1)
end

function Base.iterate(sp::SkewPartitionIterator, state)
    ix0 = state[1]
    n = state[2]
    n <= 0 && return nothing
    off = get_next_range(n)
    ix1 = ix0+off-1
    (ix0, ix1), (1+ix1, n-off)
end

function skew_binomial_lengths(xs)
    mapfoldl(xy -> xy[2]-xy[1]+1,
             pushfirst,
             skew_partition(xs),
             init=Linked.List{Int}())
end

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

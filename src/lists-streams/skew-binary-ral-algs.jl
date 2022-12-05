# reverse {{{
function Base.reverse(l::List)
    isempty(l) ? l : _makelist(reverse!(collect(l)))
end

function Base.reverse(d::Digit)
    revd = reverse!(collect(d))
    makedigit(revd, 1, length(revd))
end
# }}}

# halfish {{{

function digit_to_list(digit::Digit)
    T = eltype(digit)
    e = Linked.List{ Digit{T} }()
    ds = pushfirst(e, digit)
    List{T}(ds)
end


function PureFun.halfish(d::Digit)
    if isleaf(d)
        f = digit_to_list(d)
        r = empty(f)
        return f,r
    end
    T = eltype(d)
    tr = tree(d)
    x = elem(tr)
    w = div(length(d)-1, 2)
    front = cons(x, digit_to_list(Digit(w, tr.t1)))
    rest = digit_to_list(Digit(w, tr.t2))
    front, rest
end

function PureFun.halfish(l::List)
    isempty(l) && return l, l
    T = eltype(l)
    ds = digits(l)
    d = first(ds)
    isempty(popfirst(ds)) && return halfish(d)
    front_digits_reversed = empty(ds)
    while !isempty(popfirst(ds))
        d = first(ds)
        ds = popfirst(ds)
        front_digits_reversed = pushfirst(front_digits_reversed, d)
    end
    List{T}(reverse(front_digits_reversed)), digit_to_list(first(ds))
end

# }}}

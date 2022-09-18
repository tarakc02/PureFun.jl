using PureFun
using PureFun.Lazy: Stream, @cons

#=

## Example: Approximating $\pi$

This example is adapted from [Chapter 3 of Structure and Interpretation of
Computer
Programs](https://mitpress.mit.edu/sites/default/files/sicp/full-text/sicp/book/node72.html)

The summation:

```math
\frac{\pi}{4} = 1 - \frac{1}{3} + \frac{1}{5} - \frac{1}{7}
```
gives us a way to approximate $\pi$:

=#
function pi_summands(n, one)
    @cons(Float64, one/n, pi_summands(n+2, -one))
end

function approx_pi(n)
    summands = pi_summands(n, 1)
    sums = accumulate(+, summands, 0.0)
    map(x -> 4x, sums)
end

π̂ = approx_pi(1)

# The series converges slowly though. In order to see how close the estimates
# are:

map(x -> abs(π - x), π̂)

#=

## A better approximation

An *accelerator* is a function that takes a series, and returns a series that
converges to the same sum, but more quickly. The Euler transform is an
accelerator that works well on series with alternating positive/negative terms,
like we have here. It is defined as:

```math
S_{n+1} - \frac{(S_{n+1}-S_{n})^{2}}{S_{n-1} - 2S_{n} + S_{n+1}}
```

So:

=#

euler_transform(s₀, s₁, s₂) = s₂ - (s₂ - s₁)^2/(s₀ - 2s₁ + s₂)

function euler_transform(s::Stream)
    @cons(Float64,
          euler_transform(s[1], s[2], s[3]),
          euler_transform(tail(s)))
end

π̂₂ = euler_transform(approx_pi(1))

# This converges much more quickly to the true value of $\pi$

map(x -> abs(π - x), π̂₂)

# and we can reuse the accelerator to keep improving our approximation:

euler_transform(π̂₂)

# ...

π̂₂ |> euler_transform |> euler_transform |> euler_transform

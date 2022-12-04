using PureFun
using PureFun.Linked: List

#=

The [balanced parentheses
problem](https://leetcode.com/problems/valid-parentheses/):

> Given a string s containing just the characters '(', ')', '{', '}', '[' and
> ']', determine if the input string is valid.
>
> An input string is valid if:
> - Open brackets must be closed by the same type of brackets.
> - Open brackets must be closed in the correct order.

So, for example:

- `()`: valid
- `()[]{}`: valid
- `(]`: **invalid**
- `{[}`]: **invalid**
- `{[{()}]}`: valid

we start with some helper functions:

=#

isopening(char) = char ∈ [ '(', '{', '[' ];
isclosing(char) = char ∈ [ ')', '}', ']' ];

#=

`ismatching` takes a list of characters `bs`, and a closing bracket `b2`, and
tests whether the first element of `bs` is a matched opening for `b2`.

=#

function ismatching(bs, b2)
    isempty(bs) && return false
    b1 = first(bs)
    b1 == '(' && b2 == ')' ||
    b1 == '{' && b2 == '}' ||
    b1 == '[' && b2 == ']'
end;

#=

For the main logic, we traverse the characters of the input string, keeping
track of any unclosed open brackets we've seen on a stack. If we encounter a
closing bracket, we check whether it closes the most recent opening bracket,
and if it does we continue to match the previous opening bracket. We can
overload `isvalid` to do the initial setup.

=#

balanced(input) = balanced(input, empty(List(input)));

#=

By assumption, each character is either an opening bracket or a closing
bracket. If it's an opening, we continue on to verify that it is matched with a
closing later on. If it's a closing, we check that it closes the currently open
bracket -- if not, then we have an invalid string, but if it does, we remove
the current bracket from the stack and check that the remaining characters
close the remaining openings on the stack.

=#
function balanced(chars, opens)
    isempty(chars) && return isempty(opens)
    c, rest... = chars
    isopening(c) ?
        balanced(rest, c ⇀ opens) :
        ismatching(opens, c) && balanced(rest, popfirst(opens))
end;

# let's see how it works:

test_data = ["()", "()[]{}", "(]", "{[}]", "{[{()}]}"]
expected_results = [true, true, false, false, true]

actual_results = map(balanced, test_data)
all(actual_results .== expected_results)

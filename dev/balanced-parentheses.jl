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

isopening(char) = char ∈ [ '(', '{', '[' ]
isclosing(char) = char ∈ [ ')', '}', ']' ]

function bracketmatch(b1, b2)
    b1 == '(' && b2 == ')' ||
    b1 == '{' && b2 == '}' ||
    b1 == '[' && b2 == ']'
end;

#=

For the main logic, we traverse the characters of the input string, keeping
track of any unclosed open brackets we've seen on a stack. If we encounter a
closing bracket, we check whether it closes the most recent opening bracket,
and if it does we continue to match the previous opening bracket.

=#
function balanced(chars, opens)
    isempty(chars) && return isempty(opens)
    c, rest... = chars
    isopening(c) ?
        balanced(rest, c ⇀ opens) :
        valid(opens, c) && balanced(rest, popfirst(opens))
end

valid(opens, c)  = !isempty(opens) && bracketmatch(opens[1], c);

#=

We can overload `balanced` to do the initial setup:

=#

balanced(input) = balanced(input, empty(List(input)));

# let's see how it works:

test_data = ["()", "()[]{}",  "(]", "{[}]", "{[{()}]}"]
expected =  [true,   true,   false,  false,    true]

actual = map(balanced, test_data)
all(actual .== expected)

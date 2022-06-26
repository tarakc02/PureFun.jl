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

function ismatching(b1, b2)
    b1 == '(' && b2 == ')' ||
    b1 == '{' && b2 == '}' ||
    b1 == '[' && b2 == ']'
end

#=

For the main logic, we traverse the characters of the input string, keeping
track of any unclosed open brackets we've seen. If we encounter a closing
bracket, we check whether it closes the most recent opening bracket, and if it
does we continue to match the previous opening bracket. We can overload
`isvalid` to do the initial setup.

=#

function isvalid(input) 
    chars = List(input)
    isvalid(chars, List{Char}())
end


#=

Each character is either an opening bracket, a closing bracket, or we throw an
error otherwise. If it's an opening, we continue on to verify that it is
matched with a closing later on. If it's a closing, we check that it closes the
currently open bracket

=#
function isvalid(chars, opens)
    isempty(chars) && return isempty(opens)
    c = head(chars)
    rest = tail(chars)
    if isopening(c)
        isvalid(rest, cons(c, opens))
    elseif isclosing(c)
        isempty(opens) ?
            false :
            ismatching(head(opens), c) && isvalid(rest, tail(opens))
    else
        throw(DomainError(c, "character outside of valid alphabet"))
    end
end

# let's see how it works:

results = map(isvalid,
              ["()", # valid
               "()[]{}", # valid
               "(]", # NO
               "{[}]", # NO
               "{[{()}]}" # valid
              ])

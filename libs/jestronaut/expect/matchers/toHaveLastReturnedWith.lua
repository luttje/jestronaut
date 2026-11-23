local wrapAndTagVarargsOrReturn = require "jestronaut/expect/asymmetricmatchers/varargsMatching"
.wrapAndTagVarargsOrReturn
local messagesLib = require "jestronaut/expect/messages"

--- Checks that the last return of the mock function had the given values.
--- @param expect Expect
--- @param ... any
--- @return boolean
local function toHaveLastReturnedWith(expect, ...)
    local mock = messagesLib.getMock(expect)
    local expectedValues = wrapAndTagVarargsOrReturn(...)
    local results = mock.mock.results

    return expect:check(#results > 0 and mock:hasLastReturnedWith(...), function(isNot)
        return "Expected: " .. (isNot and "not " or "") .. messagesLib.formatWrappedValues(expectedValues, "nil") ..
            "\nReceived: " .. (#results > 0 and messagesLib.formatWrappedValues(results[#results], "nil") or "(no returns)") ..
            "\n\nNumber of returns: " .. #results
    end)
end

return {
    toHaveLastReturnedWith = toHaveLastReturnedWith,
    default = toHaveLastReturnedWith,
}

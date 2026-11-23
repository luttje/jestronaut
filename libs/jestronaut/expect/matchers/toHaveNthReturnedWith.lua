local wrapAndTagVarargsOrReturn = require "jestronaut/expect/asymmetricmatchers/varargsMatching"
.wrapAndTagVarargsOrReturn
local messagesLib = require "jestronaut/expect/messages"

--- Checks that the nth return of the mock function had the given values.
--- @param expect Expect
--- @param nthCall number
--- @param ... any
--- @return boolean
local function toHaveNthReturnedWith(expect, nthCall, ...)
    local mock = messagesLib.getMock(expect)
    local expectedValues = wrapAndTagVarargsOrReturn(...)
    local results = mock.mock.results

    return expect:check(nthCall <= #results and mock:hasNthReturnedWith(nthCall, ...), function(isNot)
        return "Call: " .. tostring(nthCall) ..
            "\nExpected: " .. (isNot and "not " or "") .. messagesLib.formatWrappedValues(expectedValues, "nil") ..
            "\nReceived: " .. (nthCall <= #results and messagesLib.formatWrappedValues(results[nthCall].value, "nil") or "(no such return)") ..
            "\n\nNumber of returns: " .. #results
    end)
end

return {
    toHaveNthReturnedWith = toHaveNthReturnedWith,
    default = toHaveNthReturnedWith,
}

local wrapAndTagVarargsOrReturn = require "jestronaut/expect/asymmetricmatchers/varargsMatching"
.wrapAndTagVarargsOrReturn
local messagesLib = require "jestronaut/expect/messages"

--- Checks that the mock function returned the given values at least once.
--- @param expect Expect
--- @param ... any
--- @return boolean
local function toHaveReturnedWith(expect, ...)
    local mock = messagesLib.getMock(expect)
    local expectedValues = wrapAndTagVarargsOrReturn(...)

    return expect:check(mock:hasReturnedWith(...), function(isNot)
        return "Expected: " .. (isNot and "not " or "") .. messagesLib.formatWrappedValues(expectedValues, "nil") ..
            "\n\nReceived returns:\n" .. messagesLib.formatReturns(mock)
    end)
end

return {
    toHaveReturnedWith = toHaveReturnedWith,
    default = toHaveReturnedWith,
}

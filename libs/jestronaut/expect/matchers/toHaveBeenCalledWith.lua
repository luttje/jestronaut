local wrapAndTagVarargsOrReturn = require "jestronaut/expect/asymmetricmatchers/varargsMatching"
.wrapAndTagVarargsOrReturn
local messagesLib = require "jestronaut/expect/messages"

--- Checks that the mock function was called with the given arguments at least once.
--- @param expect Expect
--- @param ... any
--- @return boolean
local function toHaveBeenCalledWith(expect, ...)
    local mock = messagesLib.getMock(expect)
    local expectedArgs = wrapAndTagVarargsOrReturn(...)

    return expect:check(mock:wasCalledWith(...), function(isNot)
        return "Expected: " .. (isNot and "not " or "") .. messagesLib.formatWrappedValues(expectedArgs, "(no arguments)") ..
            "\n\nReceived calls:\n" .. messagesLib.formatCalls(mock)
    end)
end

return {
    toHaveBeenCalledWith = toHaveBeenCalledWith,
    default = toHaveBeenCalledWith,
}

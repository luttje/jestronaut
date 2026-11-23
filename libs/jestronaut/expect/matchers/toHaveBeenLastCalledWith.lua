local wrapAndTagVarargsOrReturn = require "jestronaut/expect/asymmetricmatchers/varargsMatching"
.wrapAndTagVarargsOrReturn
local messagesLib = require "jestronaut/expect/messages"

--- Checks that the last call to the mock function had the given arguments.
--- @param expect Expect
--- @param ... any
--- @return boolean
local function toHaveBeenLastCalledWith(expect, ...)
    local mock = messagesLib.getMock(expect)
    local expectedArgs = wrapAndTagVarargsOrReturn(...)

    return expect:check(mock:wasLastCalledWith(...), function(isNot)
        local lastCall = mock.mock.lastCall

        return "Expected: " .. (isNot and "not " or "") .. messagesLib.formatWrappedValues(expectedArgs, "(no arguments)") ..
            "\nReceived: " .. (lastCall and messagesLib.formatWrappedValues(lastCall.args, "(no arguments)") or "(no calls)") ..
            "\n\nNumber of calls: " .. mock.callCount
    end)
end

return {
    toHaveBeenLastCalledWith = toHaveBeenLastCalledWith,
    default = toHaveBeenLastCalledWith,
}

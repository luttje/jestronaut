local wrapAndTagVarargsOrReturn = require "jestronaut/expect/asymmetricmatchers/varargsMatching"
.wrapAndTagVarargsOrReturn
local messagesLib = require "jestronaut/expect/messages"

--- Checks that the nth call to the mock function had the given arguments.
--- @param expect Expect
--- @param nthCall number
--- @param ... any
--- @return boolean
local function toHaveBeenNthCalledWith(expect, nthCall, ...)
    local mock = messagesLib.getMock(expect)
    local expectedArgs = wrapAndTagVarargsOrReturn(...)

    return expect:check(mock:wasNthCalledWith(nthCall, ...), function(isNot)
        local call = mock.mock.calls[nthCall]

        return "Call: " .. tostring(nthCall) ..
            "\nExpected: " .. (isNot and "not " or "") .. messagesLib.formatWrappedValues(expectedArgs, "(no arguments)") ..
            "\nReceived: " .. (call and messagesLib.formatWrappedValues(call.args, "(no arguments)") or "(no such call)") ..
            "\n\nNumber of calls: " .. mock.callCount
    end)
end

return {
    toHaveBeenNthCalledWith = toHaveBeenNthCalledWith,
    default = toHaveBeenNthCalledWith,
}

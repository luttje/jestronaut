local messagesLib = require "jestronaut/expect/messages"

--- Checks that the mock function was called exactly the given number of times.
--- @param expect Expect
--- @param times number
--- @return boolean
local function toHaveBeenCalledTimes(expect, times)
    local mock = messagesLib.getMock(expect)

    return expect:check(mock.callCount == times, function(isNot)
        return "Expected number of calls: " .. (isNot and "not " or "") .. tostring(times) ..
            "\nReceived number of calls: " .. mock.callCount
    end)
end

return {
    toHaveBeenCalledTimes = toHaveBeenCalledTimes,
    default = toHaveBeenCalledTimes,
}

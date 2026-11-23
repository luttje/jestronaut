local messagesLib = require "jestronaut/expect/messages"

--- Checks that the mock function returned exactly the given number of times.
--- @param expect Expect
--- @param times number
--- @return boolean
local function toHaveReturnedTimes(expect, times)
    local mock = messagesLib.getMock(expect)
    local returnCount = #mock.mock.results

    return expect:check(returnCount == times, function(isNot)
        return "Expected number of returns: " .. (isNot and "not " or "") .. tostring(times) ..
            "\nReceived number of returns: " .. returnCount
    end)
end

return {
    toHaveReturnedTimes = toHaveReturnedTimes,
    default = toHaveReturnedTimes,
}

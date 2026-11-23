local messagesLib = require "jestronaut/expect/messages"

--- Checks that the mock function returned at least once.
--- @param expect Expect
--- @return boolean
local function toHaveReturned(expect)
    local mock = messagesLib.getMock(expect)
    local returnCount = #mock.mock.results

    return expect:check(returnCount > 0, function(isNot)
        return "Expected number of returns: " .. (isNot and "0" or ">= 1") ..
            "\nReceived number of returns: " .. returnCount
    end)
end

return {
    toHaveReturned = toHaveReturned,
    default = toHaveReturned,
}

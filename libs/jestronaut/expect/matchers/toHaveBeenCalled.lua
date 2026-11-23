local messagesLib = require "jestronaut/expect/messages"

--- Checks that the mock function was called at least once.
--- @param expect Expect
--- @return boolean
local function toHaveBeenCalled(expect)
    local mock = messagesLib.getMock(expect)

    return expect:check(mock.callCount > 0, function(isNot)
        return "Expected number of calls: " .. (isNot and "0" or ">= 1") ..
            "\nReceived number of calls: " .. mock.callCount ..
            "\n\nCalls:\n" .. messagesLib.formatCalls(mock)
    end)
end

return {
    toHaveBeenCalled = toHaveBeenCalled,
    default = toHaveBeenCalled,
}

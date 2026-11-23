local isMockFunction = require "jestronaut/mock/mockfunction".isMockFunction
local formatLib = require "jestronaut/utils/format"

--- Checks the type of the received value, as returned by `type`. Mock functions count as functions.
--- @param expect Expect
--- @param expected string
--- @return boolean
local function toBeType(expect, expected)
    local actual = expect.actual
    local pass = type(actual) == expected or (expected == "function" and isMockFunction(actual))

    return expect:check(pass, function(isNot)
        return "Expected type: " .. (isNot and "not " or "") .. formatLib.format(expected) ..
            "\nReceived type: " .. formatLib.format(type(actual)) ..
            "\nReceived value: " .. formatLib.format(actual)
    end)
end

return {
    toBeType = toBeType,
    default = toBeType,
}

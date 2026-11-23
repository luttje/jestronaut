local formatLib = require "jestronaut/utils/format"

--- Checks the length of a table or string, as returned by the # operator.
--- @param expect Expect
--- @param length number
--- @return boolean
local function toHaveLength(expect, length)
    local actual = expect.actual

    if type(length) ~= "number" then
        expect:usageError("expected length must be a number, got " .. formatLib.format(length))
    elseif type(actual) ~= "table" and type(actual) ~= "string" then
        expect:usageError("received value must be a table or string, got " .. formatLib.format(actual))
    end

    return expect:check(#actual == length, function(isNot)
        return "Expected length: " .. (isNot and "not " or "") .. length ..
            "\nReceived length: " .. #actual ..
            "\nReceived value: " .. formatLib.format(actual)
    end)
end

return {
    toHaveLength = toHaveLength,
    default = toHaveLength,
}

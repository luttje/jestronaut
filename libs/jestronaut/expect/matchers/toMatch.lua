local formatLib = require "jestronaut/utils/format"

--- Checks that a string matches a Lua pattern.
--- @param expect Expect
--- @param pattern string
--- @return boolean
local function toMatch(expect, pattern)
    local actual = expect.actual

    if type(actual) ~= "string" then
        expect:usageError("received value must be a string, got " .. formatLib.format(actual))
    elseif type(pattern) ~= "string" then
        expect:usageError("expected pattern must be a string, got " .. formatLib.format(pattern))
    end

    local isValid, result = pcall(string.find, actual, pattern)

    if not isValid then
        expect:usageError("invalid pattern " .. formatLib.format(pattern) .. ": " .. tostring(result))
    end

    return expect:check(result ~= nil, function(isNot)
        return "Expected pattern: " .. (isNot and "not " or "") .. formatLib.format(pattern) ..
            "\nReceived string:  " .. formatLib.format(actual)
    end)
end

return {
    toMatch = toMatch,
    default = toMatch,
}

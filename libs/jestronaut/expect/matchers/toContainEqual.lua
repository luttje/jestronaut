local deepEquals = require "jestronaut/expect/matchers/toEqual".deepEquals
local formatLib = require "jestronaut/utils/format"

--- Checks that an array contains an item that recursively equals the expected item (compared like toEqual).
--- @param expect Expect
--- @param customEqualityTesters function[]
--- @param expected any
--- @return boolean
local function toContainEqual(expect, customEqualityTesters, expected)
    local actual = expect.actual

    if type(actual) ~= "table" then
        expect:usageError("received value must be a table, got " .. formatLib.format(actual))
    end

    local pass = false

    for _, item in ipairs(actual) do
        if deepEquals(item, expected, customEqualityTesters) then
            pass = true
            break
        end
    end

    return expect:check(pass, function(isNot)
        return "Expected value: " .. (isNot and "not " or "") .. formatLib.format(expected) ..
            "\nReceived array: " .. formatLib.format(actual)
    end)
end

return {
    toContainEqual = toContainEqual,

    --- @param expect Expect
    build = function(expect, customEqualityTesters)
        return function(expect, expected)
            return toContainEqual(expect, customEqualityTesters, expected)
        end
    end,
}

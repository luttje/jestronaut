local asymmetricMatcherLib = require "jestronaut/expect/asymmetricmatchers/asymmetricmatcher"
local toEqualLib = require "jestronaut/expect/matchers/toEqual"
local formatLib = require "jestronaut/utils/format"

--- Checks whether the table only has the keys 1 to n.
--- @param value table
--- @return boolean
local function isSequence(value)
    local count = 0

    for _ in pairs(value) do
        count = count + 1
    end

    return count == #value
end

--- Checks that the actual table has all keys of the expected table, with matching values. Nested tables are matched
--- the same way, except arrays which must have the same length. Other values are compared like toEqual.
--- Returns the same as deepEquals: true, or false followed by the path to the first difference and the values there.
--- @param actual any
--- @param expected any
--- @param customEqualityTesters function[]
--- @param path string
--- @return boolean, string?, any, any
local function matchesObject(actual, expected, customEqualityTesters, path)
    if type(actual) ~= "table" or type(expected) ~= "table" or asymmetricMatcherLib.isMatcher(expected) then
        return toEqualLib.deepEquals(actual, expected, customEqualityTesters, nil, path)
    end

    if isSequence(expected) and #actual ~= #expected then
        return false, path, actual, expected
    end

    for key, expectedValue in pairs(expected) do
        local isMatch, differencePath, actualAtPath, expectedAtPath = matchesObject(
            actual[key], expectedValue, customEqualityTesters, path .. formatLib.formatPathKey(key)
        )

        if not isMatch then
            return false, differencePath, actualAtPath, expectedAtPath
        end
    end

    return true
end

--- Checks that a table matches a subset of the properties of the expected table.
--- @param expect Expect
--- @param customEqualityTesters function[]
--- @param expected table
--- @return boolean
local function toMatchObject(expect, customEqualityTesters, expected)
    local actual = expect.actual

    if type(actual) ~= "table" then
        expect:usageError("received value must be a table, got " .. formatLib.format(actual))
    elseif type(expected) ~= "table" then
        expect:usageError("expected value must be a table, got " .. formatLib.format(expected))
    end

    local isMatch, differencePath, actualAtPath, expectedAtPath = matchesObject(actual, expected,
        customEqualityTesters, "")

    return expect:check(isMatch, function(isNot)
        return toEqualLib.buildEqualityDetails(actual, expected, isNot, differencePath, actualAtPath, expectedAtPath)
    end)
end

return {
    toMatchObject = toMatchObject,

    --- @param expect Expect
    build = function(expect, customEqualityTesters)
        return function(expect, expected)
            return toMatchObject(expect, customEqualityTesters, expected)
        end
    end,
}

local wrapAndTagVarargsOrReturn = require "jestronaut/expect/asymmetricmatchers/varargsMatching"
.wrapAndTagVarargsOrReturn
local asymmetricMatcherLib = require "jestronaut/expect/asymmetricmatchers/asymmetricmatcher"
local tableLib = require "jestronaut/utils/tables"

--- Formats a table key as it would appear in a path, e.g. `.name`, `[1]` or `["some key"]`.
--- @param key any
--- @return string
local function formatKey(key)
    if type(key) == "string" then
        if key:match("^[%a_][%w_]*$") then
            return "." .. key
        end

        return "[" .. string.format("%q", key) .. "]"
    end

    return "[" .. tostring(key) .. "]"
end

--- Formats a value for use in an error message. Strings are quoted so "1" and 1 can be told apart.
--- @param value any
--- @return string
local function formatValue(value)
    if type(value) == "string" then
        return string.format("%q", value)
    elseif type(value) == "table" and not asymmetricMatcherLib.isMatcher(value) then
        return "table: '" .. tableLib.implode(value, ", ") .. "'"
    end

    return tostring(value)
end

--- Recursively checks whether two values are equal, the way Jest's toEqual does:
--- - tables are equal when they have the same keys with (recursively) equal values, metatables are ignored;
--- - asymmetric matchers (like expect.anything()) on either side are used to match the other value;
--- - NaN is equal to NaN;
--- - custom equality testers are consulted first, at every level. They receive (actual, expected) and return
---   true or false to decide, or nil to fall back to the default comparison.
---
--- Returns true when equal. Otherwise returns false, followed by the path to the first difference (empty when the
--- values themselves differ) and the actual and expected values at that path.
--- @param actual any
--- @param expected any
--- @param customEqualityTesters? function[]
--- @param path? string
--- @param seen? table
--- @return boolean, string?, any, any
local function deepEquals(actual, expected, customEqualityTesters, path, seen)
    path = path or ""

    if customEqualityTesters then
        for _, tester in ipairs(customEqualityTesters) do
            local result = tester(actual, expected)

            if result ~= nil then
                if result then
                    return true
                end

                return false, path, actual, expected
            end
        end
    end

    if asymmetricMatcherLib.isMatcher(expected) then
        if asymmetricMatcherLib.matches(expected, actual) then
            return true
        end

        return false, path, actual, expected
    elseif asymmetricMatcherLib.isMatcher(actual) then
        if asymmetricMatcherLib.matches(actual, expected) then
            return true
        end

        return false, path, actual, expected
    end

    if rawequal(actual, expected) then
        return true
    end

    local actualType, expectedType = type(actual), type(expected)

    -- NaN is the only value that isn't equal to itself
    if actualType == "number" and expectedType == "number" and actual ~= actual and expected ~= expected then
        return true
    end

    if actualType ~= "table" or expectedType ~= "table" then
        return false, path, actual, expected
    end

    -- Guard against infinite recursion on cyclic tables: a pair that is already being compared further up is
    -- assumed equal, any real difference will be found elsewhere.
    seen = seen or {}
    seen[actual] = seen[actual] or {}

    if seen[actual][expected] then
        return true
    end

    seen[actual][expected] = true

    for key, expectedValue in pairs(expected) do
        local isEqual, differencePath, actualAtPath, expectedAtPath = deepEquals(
            actual[key], expectedValue, customEqualityTesters, path .. formatKey(key), seen
        )

        if not isEqual then
            return false, differencePath, actualAtPath, expectedAtPath
        end
    end

    for key, actualValue in pairs(actual) do
        if expected[key] == nil then
            return false, path .. formatKey(key), actualValue, nil
        end
    end

    return true
end

--- Checks that the actual value recursively equals the expected value.
--- @param expect Expect
--- @param customEqualityTesters function[]
--- @param ... any
--- @return boolean
local function toEqual(expect, customEqualityTesters, ...)
    local actual = expect.actual
    local expected = wrapAndTagVarargsOrReturn(...)
    local isEqual, differencePath, actualAtPath, expectedAtPath = deepEquals(actual, expected, customEqualityTesters)

    if isEqual == expect.inverse then
        local message = "Expected " .. formatValue(actual) .. (expect.inverse and " not" or "") ..
            " to equal " .. formatValue(expected)

        if not isEqual and differencePath ~= "" then
            message = message .. "\n  Difference at " .. differencePath .. ": expected " .. formatValue(expectedAtPath) ..
                ", received " .. formatValue(actualAtPath)
        end

        error(message)
    end

    return true
end

return {
    toEqual = toEqual,
    deepEquals = deepEquals,

    --- @param expect Expect
    build = function(expect, customEqualityTesters)
        return function(expect, ...)
            return toEqual(expect, customEqualityTesters or {}, ...)
        end
    end,
}

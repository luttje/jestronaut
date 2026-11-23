local wrapAndTagVarargsOrReturn = require "jestronaut/expect/asymmetricmatchers/varargsMatching"
.wrapAndTagVarargsOrReturn
local asymmetricMatcherLib = require "jestronaut/expect/asymmetricmatchers/asymmetricmatcher"
local formatLib = require "jestronaut/utils/format"

--- Recursively checks whether two values are equal, the way Jest's toEqual does:
--- - tables are equal when they have the same keys with (recursively) equal values;
--- - metatables are ignored, unless `options.strict` is set (as toStrictEqual does);
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
--- @param options? { strict?: boolean }
--- @param path? string
--- @param seen? table
--- @return boolean, string?, any, any
local function deepEquals(actual, expected, customEqualityTesters, options, path, seen)
    path = path or ""
    options = options or {}

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

    if options.strict and getmetatable(actual) ~= getmetatable(expected) then
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
            actual[key], expectedValue, customEqualityTesters, options, path .. formatLib.formatPathKey(key), seen
        )

        if not isEqual then
            return false, differencePath, actualAtPath, expectedAtPath
        end
    end

    for key, actualValue in pairs(actual) do
        if expected[key] == nil then
            return false, path .. formatLib.formatPathKey(key), actualValue, nil
        end
    end

    return true
end

--- Builds the failure details for equality matchers.
--- @param actual any
--- @param expected any
--- @param isNot boolean
--- @param differencePath string?
--- @param actualAtPath any
--- @param expectedAtPath any
--- @return string
local function buildEqualityDetails(actual, expected, isNot, differencePath, actualAtPath, expectedAtPath)
    local details = "Expected: " .. (isNot and "not " or "") .. formatLib.format(expected) ..
        "\nReceived: " .. formatLib.format(actual)

    if not isNot and differencePath and differencePath ~= "" then
        details = details .. "\n\nDifference at " .. differencePath .. ": expected " .. formatLib.format(expectedAtPath) ..
            ", received " .. formatLib.format(actualAtPath)
    end

    return details
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

    return expect:check(isEqual, function(isNot)
        return buildEqualityDetails(actual, expected, isNot, differencePath, actualAtPath, expectedAtPath)
    end)
end

return {
    toEqual = toEqual,
    deepEquals = deepEquals,
    buildEqualityDetails = buildEqualityDetails,

    --- @param expect Expect
    build = function(expect, customEqualityTesters)
        return function(expect, ...)
            return toEqual(expect, customEqualityTesters or {}, ...)
        end
    end,
}

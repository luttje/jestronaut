local toEqualLib = require "jestronaut/expect/matchers/toEqual"

--- Use .toStrictEqual to test that values have the same structure and type. Differences from .toEqual:
--- - tables (at every level) must have the same metatable, so instances of different classes are not equal.
--- - custom equality testers are not used.
--- @param expect Expect
--- @param expected any
--- @return boolean
local function toStrictEqual(expect, expected)
    local actual = expect.actual
    local isEqual, differencePath, actualAtPath, expectedAtPath = toEqualLib.deepEquals(actual, expected, nil,
        { strict = true })

    return expect:check(isEqual, function(isNot)
        local details = toEqualLib.buildEqualityDetails(actual, expected, isNot, differencePath, actualAtPath,
            expectedAtPath)

        if not isNot and toEqualLib.deepEquals(actual, expected) then
            details = details .. "\n\nThe values are equal, but their metatables differ."
        end

        return details
    end)
end

return {
    toStrictEqual = toStrictEqual,
    default = toStrictEqual,
}

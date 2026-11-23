local formatLib = require "jestronaut/utils/format"

--- Builds a matcher that compares the received number to the expected number.
--- @param operator string Shown in failure messages, e.g. ">".
--- @param compare fun(actual: number, expected: number): boolean
--- @return table # A matcher module.
local function buildComparisonMatcher(operator, compare)
    local function matcher(expect, expected)
        local actual = expect.actual

        if type(actual) ~= "number" then
            expect:usageError("received value must be a number, got " .. formatLib.format(actual))
        elseif type(expected) ~= "number" then
            expect:usageError("expected value must be a number, got " .. formatLib.format(expected))
        end

        return expect:check(compare(actual, expected), function(isNot)
            return "Expected: " .. (isNot and "not " or "") .. operator .. " " .. formatLib.format(expected) ..
                "\nReceived: " .. formatLib.format(actual)
        end)
    end

    return {
        default = matcher,
    }
end

return {
    buildComparisonMatcher = buildComparisonMatcher,
}

local formatLib = require "jestronaut/utils/format"

--- Checks that a number is close to the expected number: their difference must be less than 10^-numDigits / 2.
--- With the default of 2 digits, the difference must be less than 0.005.
--- @param expect Expect
--- @param expected number
--- @param numDigits? number
--- @return boolean
local function toBeCloseTo(expect, expected, numDigits)
    local actual = expect.actual
    numDigits = numDigits or 2

    if type(actual) ~= "number" then
        expect:usageError("received value must be a number, got " .. formatLib.format(actual))
    elseif type(expected) ~= "number" then
        expect:usageError("expected value must be a number, got " .. formatLib.format(expected))
    end

    local maxDifference = 10 ^ -numDigits / 2
    local difference = math.abs(expected - actual)
    local pass = (actual == expected) or difference < maxDifference

    return expect:check(pass, function(isNot)
        return "Expected: " .. (isNot and "not " or "") .. formatLib.format(expected) ..
            "\nReceived: " .. formatLib.format(actual) ..
            "\n\nExpected precision:    " .. numDigits ..
            "\nExpected difference: " .. (isNot and ">= " or "< ") .. formatLib.format(maxDifference) ..
            "\nReceived difference: " .. formatLib.format(difference)
    end)
end

return {
    toBeCloseTo = toBeCloseTo,
    default = toBeCloseTo,
}

local formatLib = require "jestronaut/utils/format"

--- Checks that the received value is NaN (not a number), the only value that isn't equal to itself.
--- @param expect Expect
--- @return boolean
local function toBeNaN(expect)
    local actual = expect.actual

    return expect:check(type(actual) == "number" and actual ~= actual, function(isNot)
        return "Expected: " .. (isNot and "not " or "") .. "NaN\nReceived: " .. formatLib.format(actual)
    end)
end

return {
    toBeNaN = toBeNaN,
    default = toBeNaN,
}

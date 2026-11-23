local deepEquals = require "jestronaut/expect/matchers/toEqual".deepEquals
local formatLib = require "jestronaut/utils/format"

--- Checks that the received value is the expected value: the same table, function or userdata, or an equal string,
--- number, boolean or nil. NaN is the same as NaN. Metatable __eq methods are not used, use toEqual for that.
--- @param expect Expect
--- @param expected any
--- @return boolean
local function toBe(expect, expected)
    local actual = expect.actual
    local pass = rawequal(actual, expected)
        or (type(actual) == "number" and type(expected) == "number" and actual ~= actual and expected ~= expected)

    return expect:check(pass, function(isNot)
        local details = "Expected: " .. (isNot and "not " or "") .. formatLib.format(expected) ..
            "\nReceived: " .. formatLib.format(actual)

        if not isNot and type(actual) == "table" and type(expected) == "table" and deepEquals(actual, expected) then
            details = details ..
                "\n\nThe tables have the same contents, but are different tables. Use toEqual to compare contents."
        end

        return details
    end)
end

return {
    toBe = toBe,
    default = toBe,
}

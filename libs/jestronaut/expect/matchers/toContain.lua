local formatLib = require "jestronaut/utils/format"

--- Checks that an array contains the expected item (compared with toBe semantics), or that a string contains the
--- expected substring.
--- @param expect Expect
--- @param expected any
--- @return boolean
local function toContain(expect, expected)
    local actual = expect.actual
    local pass = false

    if type(actual) == "string" then
        if type(expected) ~= "string" then
            expect:usageError("expected value must be a string when the received value is a string, got " ..
                formatLib.format(expected))
        end

        pass = actual:find(expected, 1, true) ~= nil
    elseif type(actual) == "table" then
        for _, item in ipairs(actual) do
            if rawequal(item, expected)
                or (type(item) == "number" and type(expected) == "number" and item ~= item and expected ~= expected) then
                pass = true
                break
            end
        end
    else
        expect:usageError("received value must be a table or string, got " .. formatLib.format(actual))
    end

    return expect:check(pass, function(isNot)
        return "Expected value: " .. (isNot and "not " or "") .. formatLib.format(expected) ..
            "\nReceived " .. (type(actual) == "string" and "string" or "array") .. ": " .. formatLib.format(actual)
    end)
end

return {
    toContain = toContain,
    default = toContain,
}

local formatLib = require "jestronaut/utils/format"

--- Checks that the received value is nil.
--- @param expect Expect
--- @return boolean
local function toBeNil(expect)
    return expect:check(expect.actual == nil, function(isNot)
        return "Expected: " .. (isNot and "not " or "") .. "nil\nReceived: " .. formatLib.format(expect.actual)
    end)
end

return {
    toBeNil = toBeNil,
    default = toBeNil,
}

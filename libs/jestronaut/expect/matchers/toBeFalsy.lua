local formatLib = require "jestronaut/utils/format"

--- Checks that the received value is false or nil.
--- @param expect Expect
--- @return boolean
local function toBeFalsy(expect)
    return expect:check(not expect.actual, function()
        return "Received: " .. formatLib.format(expect.actual)
    end)
end

return {
    toBeFalsy = toBeFalsy,
    default = toBeFalsy,
}

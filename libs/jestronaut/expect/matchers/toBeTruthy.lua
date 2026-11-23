local formatLib = require "jestronaut/utils/format"

--- Checks that the received value is neither false nor nil.
--- @param expect Expect
--- @return boolean
local function toBeTruthy(expect)
    return expect:check(expect.actual, function()
        return "Received: " .. formatLib.format(expect.actual)
    end)
end

return {
    toBeTruthy = toBeTruthy,
    default = toBeTruthy,
}

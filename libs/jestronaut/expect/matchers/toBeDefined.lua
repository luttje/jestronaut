local formatLib = require "jestronaut/utils/format"

--- Checks that the received value is not nil.
--- @param expect Expect
--- @return boolean
local function toBeDefined(expect)
    return expect:check(expect.actual ~= nil, function()
        return "Received: " .. formatLib.format(expect.actual)
    end)
end

return {
    toBeDefined = toBeDefined,
    default = toBeDefined,
}

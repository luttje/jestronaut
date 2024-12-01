local wrapAndTagVarargsOrReturn = require "jestronaut/expect/asymmetricmatchers/varargsMatching"
.wrapAndTagVarargsOrReturn
local tableLib = require "jestronaut/utils/tables"

--- @param expect Expect
--- @param nthCall number
--- @param ... any
local function toHaveNthReturnedWith(expect, nthCall, ...)
    local actual = expect.actual

    if not expect:checkEquals(true, actual:hasNthReturnedWith(nthCall, ...)) then
        local args = wrapAndTagVarargsOrReturn(...)

        if tableLib.count(args) == 0 then
            error("Expected " ..
            tostring(actual) ..
            " to have returned with no arguments (on call " ..
            nthCall .. ") but it returned with " .. tableLib.implode(actual:getReturnedValue(nthCall), ", "))
        else
            error("Expected " ..
            tostring(actual) ..
            " to have last returned with " ..
            tableLib.implode(args, ", ") ..
            " (on call " ..
            nthCall .. ") but it returned with " .. tableLib.implode(actual:getReturnedValue(nthCall), ", "))
        end
    end

    return true
end

return {
    toHaveNthReturnedWith = toHaveNthReturnedWith,
    default = toHaveNthReturnedWith,
}

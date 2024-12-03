local wrapAndTagVarargsOrReturn = require "jestronaut/expect/asymmetricmatchers/varargsMatching"
.wrapAndTagVarargsOrReturn
local tableLib = require "jestronaut/utils/tables"

--- @param expect Expect
--- @param ... any
local function toHaveBeenCalledWith(expect, ...)
    local actual = expect.actual

    if not expect:checkEquals(true, actual:wasCalledWith(...)) then
        local args = wrapAndTagVarargsOrReturn(...)

        if (not actual:wasCalled()) then
            error("Expected " .. tostring(actual) .. " to have been called but it was never called")
        elseif (type(args) == "table") then
            if tableLib.count(args) == 0 then
                error("Expected " ..
                tostring(actual) ..
                " to have been called with no arguments but it was called with " ..
                tableLib.implode(actual:getAllCallArgs(), ", "))
            else
                error("Expected " ..
                tostring(actual) ..
                " to have been called with " ..
                tableLib.implode(args, ", ") ..
                " but it was called with " .. tableLib.implode(actual:getAllCallArgs(), ", "))
            end
        else
            error(
                "Expected " .. tostring(actual) .. " to have been called with " .. tostring(args)
                .. " but it was called with " .. tableLib.implode(actual:getAllCallArgs(), ", ")
            )
        end
    end

    return true
end

return {
    toHaveBeenCalledWith = toHaveBeenCalledWith,
    default = toHaveBeenCalledWith,
}

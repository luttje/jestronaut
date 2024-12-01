--- @param expect Expect
--- @return boolean
local function toBeDefined(expect)
    if not expect:checkEquals(true, expect.actual ~= nil) then
        error("Expected " .. tostring(expect.actual) .. " to be defined")
    end

    return true
end

return {
    toBeDefined = toBeDefined,
    default = toBeDefined,
}

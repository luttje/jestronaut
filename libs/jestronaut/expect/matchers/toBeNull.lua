---
--- @param expect Expect
--- @return boolean
local function toBeNull(expect)
    if not expect:checkEquals(true, expect.actual == nil) then
        error("Expected " .. tostring(expect.actual) .. " to be null") -- TODO: This should be "to be nil" instead of "to be null", additionally Garry's Mod Lua actually has a NULL value
    end

    return true
end

return {
    toBeNull = toBeNull,
    default = toBeNull,
}

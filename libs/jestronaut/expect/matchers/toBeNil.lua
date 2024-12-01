--- @param expect Expect
--- @return boolean
local function toBeNil(expect)
    if not expect:checkEquals(true, expect.actual == nil) then
        error("Expected " .. tostring(expect.actual) .. " to be undefined")
    end

    return true
end

return {
    toBeNil = toBeNil,
    default = toBeNil,
}

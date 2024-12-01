--- Determines whether two values are the same.
--- @param expect Expect
--- @param expected any
--- @return boolean
local function toMatch(expect, expected)
    local actual = expect.actual

    if not expect:checkEquals(true, string.find(actual, expected) > 0) then
        error("Expected '" ..
        tostring(actual) .. "'" .. (expect.inverse and " not " or "") .. " to match " .. tostring(expected))
    end

    return true
end

return {
    toMatch = toMatch,

    --- @param expect Expect
    build = function(expect, customEqualityTesters)
        -- TODO: customEqualityTesters
        return function(expect, sample)
            return toMatch(expect, sample)
        end
    end,
}

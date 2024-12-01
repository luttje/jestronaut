---
--- @param expect Expect
--- @param length any
--- @return boolean
local function toHaveLength(expect, length)
    local actual = expect.actual

    if (type(length) ~= 'number') then
        error("Expected " .. tostring(length) .. " to be a number")
    end

    if (type(actual) ~= 'table' and type(actual) ~= 'string') then
        error("Expected " .. tostring(actual) .. " to be a table or string")
    end

    if not expect:checkEquals(true, #actual == length) then
        error("Expected " ..
        tostring(actual) .. " to have length " .. tostring(length) .. " but it has length " .. tostring(#actual))
    end

    return true
end

return {
    toHaveLength = toHaveLength,
    default = toHaveLength,
}

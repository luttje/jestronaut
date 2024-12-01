local tableLib = require "jestronaut/utils/tables"

--- Checks that a JavaScript object matches a subset of the properties of an object. It will match received objects with properties that are not in the expected object.
--- You can also pass an array of objects, in which case the method will return true only if each object in the received array matches (in the toMatchObject sense described above) the corresponding object in the expected array. This is useful if you want to check that two arrays match in their number of elements, as opposed to arrayContaining, which allows for extra elements in the received array..
--- @param expect Expect
--- @param expected any
--- @return boolean
local function toMatchObject(expect, expected)
    local actual = expect.actual

    if not expect:checkEquals(true, tableLib.isSubset(expected, actual)) then
        error("Expected '" ..
        tostring(actual) .. "'" .. (expect.inverse and " not " or "") .. " to match object " .. tostring(expected))
    end

    return true
end

return {
    toMatch = toMatchObject,

    --- @param expect Expect
    build = function(expect, customEqualityTesters)
        -- TODO: customEqualityTesters
        return function(expect, sample)
            return toMatchObject(expect, sample)
        end
    end,
}

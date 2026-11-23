local deepEquals = require "jestronaut/expect/matchers/toEqual".deepEquals
local formatLib = require "jestronaut/utils/format"

--- Turns a property path into a list of keys. Strings like "a.b[1].c" are split on dots, with [n] selecting numeric
--- keys. Tables are used as the list of keys as they are, which also allows keys that contain dots.
--- @param propertyPath string|table
--- @return any[]?
local function parsePropertyPath(propertyPath)
    if type(propertyPath) == "table" then
        return propertyPath
    elseif type(propertyPath) ~= "string" then
        return nil
    end

    local keys = {}

    for part in propertyPath:gmatch("[^%.]+") do
        local name, indexes = part:match("^([^%[]*)(.*)$")

        if name ~= "" then
            table.insert(keys, name)
        end

        for index in indexes:gmatch("%[(%d+)%]") do
            table.insert(keys, tonumber(index))
        end
    end

    return keys
end

--- Formats a list of keys as a path, e.g. `a.b[1]`.
--- @param keys any[]
--- @return string
local function formatPath(keys)
    local parts = {}

    for i, key in ipairs(keys) do
        local formatted = formatLib.formatPathKey(key)
        parts[i] = (i == 1 and formatted:sub(1, 1) == ".") and formatted:sub(2) or formatted
    end

    return table.concat(parts)
end

--- Checks that a table has a (nested) property, and optionally that the property equals a value (compared like
--- toEqual). Properties set to false count as present, properties set to nil don't.
--- @param expect Expect
--- @param propertyPath string|table
--- @param ... any The expected value, if one is given.
--- @return boolean
local function toHaveProperty(expect, propertyPath, ...)
    local actual = expect.actual
    local hasExpectedValue = select("#", ...) > 0
    local expectedValue = ...

    if type(actual) ~= "table" then
        expect:usageError("received value must be a table, got " .. formatLib.format(actual))
    end

    local keys = parsePropertyPath(propertyPath)

    if not keys or #keys == 0 then
        expect:usageError("expected path must be a non-empty string or table, got " .. formatLib.format(propertyPath))
    end

    local current = actual
    local foundKeys = {}
    local hasPath = true

    for _, key in ipairs(keys) do
        if type(current) ~= "table" or current[key] == nil then
            hasPath = false
            break
        end

        current = current[key]
        table.insert(foundKeys, key)
    end

    local pass = hasPath and (not hasExpectedValue or deepEquals(current, expectedValue))

    return expect:check(pass, function(isNot)
        local details = "Expected path: " .. (isNot and not hasExpectedValue and "not " or "") .. formatPath(keys)

        if not hasPath then
            details = details .. "\nReceived path: " .. (#foundKeys > 0 and formatPath(foundKeys) or "(none)")
        elseif hasExpectedValue then
            details = details .. "\n\nExpected value: " .. (isNot and "not " or "") .. formatLib.format(expectedValue) ..
                "\nReceived value: " .. formatLib.format(current)
        end

        return details .. "\n\nReceived: " .. formatLib.format(actual)
    end)
end

return {
    toHaveProperty = toHaveProperty,
    default = toHaveProperty,
}

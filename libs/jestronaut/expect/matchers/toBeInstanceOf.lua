local metatableLib = require "jestronaut/utils/metatables"
local formatLib = require "jestronaut/utils/format"

--- Checks that the received value is an instance of the given class (a table, as created by TypeScriptToLua), or
--- has the given type name when a string is passed.
--- @param expect Expect
--- @param class table|string
--- @return boolean
local function toBeInstanceOf(expect, class)
    local actual = expect.actual
    local pass

    if type(class) == "table" then
        pass = (class.constructor and metatableLib.instanceOf(actual, class.constructor))
            or metatableLib.instanceOf(actual, class)
    elseif type(class) == "string" then
        pass = type(actual) == class
    else
        expect:usageError("expected value must be a class (table) or type name (string), got " ..
            formatLib.format(class))
    end

    return expect:check(pass, function(isNot)
        local className = type(class) == "table" and (class.name or tostring(class)) or class

        return "Expected constructor: " .. (isNot and "not " or "") .. tostring(className) ..
            "\nReceived value: " .. formatLib.format(actual)
    end)
end

return {
    toBeInstanceOf = toBeInstanceOf,
    default = toBeInstanceOf,
}

local metatableLib = require "jestronaut/utils/metatables"
local formatLib = require "jestronaut/utils/format"

--- Gets the message of an error value: the `message` field of error tables, or the value itself as a string.
--- @param err any
--- @return string
local function getErrorMessage(err)
    if type(err) == "table" and err.message ~= nil then
        return tostring(err.message)
    end

    return tostring(err)
end

--- Checks whether a message contains the expected text, either literally or as a Lua pattern.
--- @param message string
--- @param expected string
--- @return boolean
local function messageMatches(message, expected)
    if message:find(expected, 1, true) then
        return true
    end

    local isValidPattern, result = pcall(string.find, message, expected)

    return isValidPattern and result ~= nil
end

--- Checks that calling the received function throws an error. Optionally checks that the error message contains a
--- string (literally or as a Lua pattern), or that the error is an instance of a class.
--- @param expect Expect
--- @param expected? string|table
--- @return boolean
local function toThrowError(expect, expected)
    local actual = expect.actual
    local isCallable = type(actual) == "function"
        or (type(getmetatable(actual)) == "table" and getmetatable(actual).__call ~= nil)

    if not isCallable then
        expect:usageError("received value must be a function, got " .. formatLib.format(actual))
    elseif expected ~= nil and type(expected) ~= "string" and type(expected) ~= "table" then
        expect:usageError("expected value must be a string or class (table), got " .. formatLib.format(expected))
    end

    local success, err = pcall(actual)
    local threw = not success
    local pass = threw

    if threw and type(expected) == "string" then
        pass = messageMatches(getErrorMessage(err), expected)
    elseif threw and type(expected) == "table" then
        local isInstance = function()
            return (expected.constructor and metatableLib.instanceOf(err, expected.constructor))
                or metatableLib.instanceOf(err, expected)
        end
        local isValid, result = pcall(isInstance)
        pass = isValid and result or false
    end

    return expect:check(pass, function(isNot)
        if not threw then
            return "Received function did not throw"
        end

        local received = "Received error: " .. formatLib.format(getErrorMessage(err))

        if type(expected) == "string" then
            return "Expected message: " .. (isNot and "not " or "") .. formatLib.format(expected) .. "\n" .. received
        elseif type(expected) == "table" then
            return "Expected constructor: " .. (isNot and "not " or "") .. tostring(expected.name or expected) ..
                "\n" .. received
        end

        return "Received function threw, but was expected not to\n" .. received
    end)
end

return {
    toThrowError = toThrowError,
    default = toThrowError,
}

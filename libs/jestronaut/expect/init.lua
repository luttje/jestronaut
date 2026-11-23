local wrapAndTagVarargsOrReturn = require "jestronaut/expect/asymmetricmatchers/varargsMatching"
.wrapAndTagVarargsOrReturn
local callRespectingRequireOverride = require "jestronaut/utils/require".callRespectingRequireOverride
local makeIndexableFunction = require "jestronaut/utils/metatables".makeIndexableFunction
local functionLib = require "jestronaut/utils/functions"
local stateLib = require "jestronaut/environment/state"

local customEqualityTesters = {}
local customMatchers = {}
local expect
local runCustomMatcher

local modifiers = {
    ["not"] = function(expect)
        expect.inverse = true
        return expect
    end,
}

local function getMatcher(key)
    if customMatchers[key] then
        return customMatchers[key]
    end

    local modulePath = 'jestronaut/expect/matchers/' .. key
    local success, matcherOrError = callRespectingRequireOverride(function()
        return pcall(require, modulePath)
    end)

    if not success then
        if not (matcherOrError:find("module '" .. modulePath .. "' not found")) then
            error(matcherOrError)
        end

        return nil
    end

    return matcherOrError
end


local function getAsymmetricMatcher(key)
    local modulePath = 'jestronaut/expect/asymmetricmatchers/' .. key
    local success, matcherOrError = callRespectingRequireOverride(function()
        return pcall(require, modulePath)
    end)

    if not success then
        if not (matcherOrError:find("module '" .. modulePath .. "' not found")) then
            error(matcherOrError)
        end

        return nil
    end

    return matcherOrError
end

--- Builds the first line of a failure message, e.g. `expect(received)["not"]:toBe()`. Matchers can set
--- `receivedName` on the expect to show something more specific than "received", like the name of a mock.
--- @param expect Expect
--- @return string
local function getMatcherHint(expect)
    return "expect(" .. (rawget(expect, "receivedName") or "received") .. ")" ..
        (expect.inverse and '["not"]' or "") .. ":" .. tostring(expect.matcherName) .. "()"
end

--- @class Expect
--- @field actual any
--- @field inverse boolean True when the matcher was preceded by `["not"]`.
--- @field matcherName string The name of the matcher being run.
local EXPECT_META = {
    actual = nil,

    --- Passes when `pass` is true, or when it is false and the matcher was preceded by `["not"]`. Otherwise fails the
    --- assertion with a message made of the matcher hint and the details.
    --- @param self Expect
    --- @param pass any Whether the received value satisfies the matcher, ignoring `not`.
    --- @param buildDetails? fun(isNot: boolean): string? Explains the failure, e.g. "Expected: 5\nReceived: 3".
    --- @return boolean
    check = function(self, pass, buildDetails)
        if (not not pass) ~= self.inverse then
            return true
        end

        local details = buildDetails and buildDetails(self.inverse)

        error(getMatcherHint(self) .. (details and ("\n\n" .. details) or ""), 0)
    end,

    --- Fails the assertion because the matcher was used incorrectly, e.g. with a value of the wrong type.
    --- Fails regardless of `not`.
    --- @param self Expect
    --- @param details string
    usageError = function(self, details)
        error(getMatcherHint(self) .. "\n\nMatcher error: " .. details, 0)
    end,
}

--- Runs a matcher added with expect.extend. Like in Jest, it receives the received value followed by the arguments
--- passed to the matcher, and returns a table with `pass` (boolean) and `message` (string, or a function that
--- receives whether `not` was used and returns a string).
--- @param matcher function
--- @param expectInstance Expect
--- @return boolean
function runCustomMatcher(matcher, expectInstance, ...)
    local result = matcher(expectInstance.actual, ...)

    if type(result) ~= "table" or result.pass == nil then
        expectInstance:usageError("custom matchers must return a table with a `pass` field, got " .. tostring(result))
    end

    return expectInstance:check(result.pass, function(isNot)
        local message = result.message

        if type(message) == "function" then
            return message(isNot)
        end

        return message ~= nil and tostring(message) or nil
    end)
end

EXPECT_META.__index = function(self, key)
    if EXPECT_META[key] ~= nil then
        return EXPECT_META[key]
    end

    if key == 'actual' then
        local selfActual = rawget(self, 'actual')

        if (selfActual and type(selfActual) == 'table' and selfActual.isExpect) then
            local actual = selfActual[key]

            if actual ~= nil then
                return actual
            end
        end

        return selfActual
    end

    local modifier = modifiers[key]

    if modifier then
        return modifier(self)
    end

    local matcher = getMatcher(key)
    if matcher then
        local matcherFunc

        if type(matcher) == "function" then
            matcherFunc = function(expectInstance, ...)
                return runCustomMatcher(matcher, expectInstance, ...)
            end
        elseif matcher.build ~= nil then
            matcherFunc = matcher.build(self, customEqualityTesters)
        else
            matcherFunc = matcher.default
        end

        rawset(self, "matcherName", key)

        return functionLib.makeFunctionShim(matcherFunc, function(success, ...)
            stateLib.incrementAssertionCount()
        end)
    end

    local asymmetricMatcher = getAsymmetricMatcher(key)
    if asymmetricMatcher then
        if asymmetricMatcher.build ~= nil then
            return asymmetricMatcher.build(self, customEqualityTesters)
        end

        return asymmetricMatcher.default
    end

    error('Unknown (asymmetric) matcher or modifier: ' .. key)
end

function expect(...)
    local expectInstance = {
        actual = wrapAndTagVarargsOrReturn(...),
        inverse = false,
    }

    setmetatable(expectInstance, EXPECT_META)

    return expectInstance
end

--- Exposes the expect function to the global environment.
--- @param targetEnvironment table
local function exposeTo(targetEnvironment)
    targetEnvironment.expect = makeIndexableFunction(expect, {
        isExpect = true,

        addEqualityTesters = function(self, testers)
            for _, tester in ipairs(testers) do
                table.insert(customEqualityTesters, tester)
            end
        end,

        addSnapshotSerializer = function(self, serializer)
            --- @Not implemented
            -- TODO: You can call expect.addSnapshotSerializer to add a module that formats application-specific data structures.
        end,

        assertions = function(self, count)
            stateLib.setExpectedAssertionCount(count)
        end,

        hasAssertions = function(self)
            stateLib.setExpectAssertion()
        end,

        extend = function(self, matchers)
            for key, matcher in pairs(matchers) do
                customMatchers[key] = matcher
            end
        end,
    })

    local metaTable = getmetatable(targetEnvironment.expect)
    metaTable.__index = function(self, key)
        -- Create a new expect instance with the expect function as the value (so not the same expect instance is constantly modified)
        return expect(self)[key]
    end
end

return {
    EXPECT_META = EXPECT_META,
    expect = expect,
    exposeTo = exposeTo,
}

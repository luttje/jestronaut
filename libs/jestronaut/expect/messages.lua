local varargsMatchingLib = require "jestronaut/expect/asymmetricmatchers/varargsMatching"
local isMockFunction = require "jestronaut/mock/mockfunction".isMockFunction
local formatLib = require "jestronaut/utils/format"

--- Formats a value as stored by mock functions for call arguments and return values: nil when there were none, the
--- value itself when there was one, or a VarargsMatching wrapping several values.
--- @param wrapped any
--- @param emptyText string Shown when there are no values.
--- @return string
local function formatWrappedValues(wrapped, emptyText)
    if wrapped == nil then
        return emptyText
    elseif varargsMatchingLib.isVarargsMatcher(wrapped) then
        return formatLib.formatList(wrapped.varargs)
    end

    return formatLib.format(wrapped)
end

--- Formats a numbered list of calls or return values, one per line.
--- @param list any[] Wrapped values (see formatWrappedValues). Entries can be nil.
--- @param count number The number of entries.
--- @param emptyText string Shown when the list is empty.
--- @param valueEmptyText string Shown for an entry without values.
--- @return string
local function formatNumberedList(list, count, emptyText, valueEmptyText)
    if count == 0 then
        return "  " .. emptyText
    end

    local lines = {}

    for i = 1, count do
        lines[i] = "  " .. i .. ": " .. formatWrappedValues(list[i], valueEmptyText)
    end

    return table.concat(lines, "\n")
end

--- Gets the mock function being checked, failing with a usage error when the received value isn't one.
--- Also makes the failure message show the name of the mock.
--- @param expect Expect
--- @return MockFunction
local function getMock(expect)
    local actual = expect.actual

    if not isMockFunction(actual) then
        expect:usageError("received value must be a mock or spy function, got " .. formatLib.format(actual))
    end

    rawset(expect, "receivedName", tostring(actual))

    return actual
end

--- Formats the arguments of each call to the mock, one call per line.
--- @param mock MockFunction
--- @return string
local function formatCalls(mock)
    local calls = mock.mock.calls
    local list = {}

    for i, call in ipairs(calls) do
        list[i] = call.args
    end

    return formatNumberedList(list, #calls, "(no calls)", "(no arguments)")
end

--- Formats the values of each return of the mock, one return per line.
--- @param mock MockFunction
--- @return string
local function formatReturns(mock)
    local results = mock.mock.results
    local list = {}

    for i, result in ipairs(results) do
        list[i] = result.value
    end

    return formatNumberedList(list, #results, "(no returns)", "nil")
end

return {
    formatWrappedValues = formatWrappedValues,
    formatNumberedList = formatNumberedList,
    getMock = getMock,
    formatCalls = formatCalls,
    formatReturns = formatReturns,
}

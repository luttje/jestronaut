local varargsMatchingLib = require "jestronaut/expect/asymmetricmatchers/varargsMatching"
local allPropertyReplacements = {}
local allMocks = {}

--- @class MockFunction
local MOCK_FUNCTION_META = {
    callCount = 0,
    mockName = nil,
    mock = nil,
    _mockImplementation = nil,
    _mockImplementationStack = nil,
    _mockReturnThis = nil,
    _mockReturnValue = nil,
    _mockReturnValueStack = nil,
    _mockResolvedValue = nil,
    _mockResolvedValueStack = nil,
    _mockRejectedValue = nil,
    _mockRejectedValueStack = nil,

    __tostring = function(self)
        local name = rawget(self, "mockName")
        return tostring(name ~= nil and name or "jestronaut.fn()")
    end,

    __call = function(self, ...)
        local args = varargsMatchingLib.wrapAndTagVarargsOrReturn(...)

        local call = {
            args = args,
            context = self,
        }

        self.callCount = self.callCount + 1
        table.insert(self.mock.calls, call)
        table.insert(self.mock.instances, self)
        table.insert(self.mock.contexts, self)
        self.mock.lastCall = call

        local forcedReturn

        local storeReturn = function(...)
            local returns = varargsMatchingLib.wrapAndTagVarargsOrReturn(...)
            -- Like Jest, each result is a table, so returning nothing is recorded too
            table.insert(self.mock.results, { type = "return", value = returns })
            return returns
        end

        if #self._mockReturnValueStack > 0 then
            local results = storeReturn(table.remove(self._mockReturnValueStack, 1))
            return varargsMatchingLib.unwrapVarargsOrReturn(forcedReturn ~= nil and forcedReturn or results)
        end

        if #self._mockImplementationStack > 0 then
            local results = storeReturn(table.remove(self._mockImplementationStack, 1)(...))
            return varargsMatchingLib.unwrapVarargsOrReturn(forcedReturn ~= nil and forcedReturn or results)
        end

        if self._mockReturnThis then
            local results = storeReturn(self)
            return varargsMatchingLib.unwrapVarargsOrReturn(forcedReturn ~= nil and forcedReturn or results)
        end

        if self._mockReturnValue ~= nil then
            local results = storeReturn(self._mockReturnValue)
            return varargsMatchingLib.unwrapVarargsOrReturn(forcedReturn ~= nil and forcedReturn or results)
        end

        -- After mockReset there is no implementation, so the mock returns nothing
        if self._mockImplementation == nil then
            storeReturn()
            return
        end

        local results = storeReturn(self._mockImplementation(...))
        return varargsMatchingLib.unwrapVarargsOrReturn(forcedReturn ~= nil and forcedReturn or results)
    end,
}

MOCK_FUNCTION_META.__index = MOCK_FUNCTION_META

--- Returns the mock name string set by calling .mockName().
--- @return string
function MOCK_FUNCTION_META:getMockName()
    return self.mockName
end

--- Clears all information stored in the mockFn.mock.calls, mockFn.mock.instances, mockFn.mock.contexts and mockFn.mock.results arrays. Often this is useful when you want to clean up a mocks usage data between two assertions.
--- @return MockFunction
function MOCK_FUNCTION_META:mockClear()
    self.callCount = 0
    self.mock = {
        calls = {},
        results = {},
        instances = {},
        contexts = {},
        lastCall = nil,
    }

    return self
end

--- Does everything that mockFn.mockClear() does, and also removes any mocked return values or implementations.
--- @return MockFunction
function MOCK_FUNCTION_META:mockReset()
    self:mockClear()
    self._mockImplementation = nil
    self._mockImplementationStack = {}
    self._mockReturnThis = nil
    self._mockReturnValue = nil
    self._mockReturnValueStack = {}
    self._mockResolvedValue = nil
    self._mockResolvedValueStack = {}
    self._mockRejectedValue = nil
    self._mockRejectedValueStack = {}

    return self
end

--- Does everything that mockFn.mockReset() does, and also restores the original (non-mocked) implementation.
--- @return MockFunction
function MOCK_FUNCTION_META:mockRestore()
    self:mockReset()

    -- Spies put the original method or property back
    local restore = rawget(self, "_restore")

    if restore then
        self._restore = nil
        restore()
    end

    return self
end

--- Accepts a function that should be used as the implementation of the mock. The mock itself will still record all calls that go into and instances that come from itself – the only difference is that the implementation will also be executed when the mock is called.
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockImplementation(fn)
    self._mockImplementation = fn

    return self
end

--- Accepts a function that will be used as an implementation of the mock for one call to the mocked function. Can be chained so that multiple function calls produce different results.
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockImplementationOnce(fn)
    table.insert(self._mockImplementationStack, fn)

    return self
end

---
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockName(name)
    self.mockName = name

    return self
end

--- Sets inner implementation to return this context.
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockReturnThis()
    self._mockReturnThis = true

    return self
end

---
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockReturnValue(...)
    self._mockReturnValue = varargsMatchingLib.wrapAndTagVarargsOrReturn(...)

    return self
end

---
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockReturnValueOnce(...)
    table.insert(self._mockReturnValueStack, varargsMatchingLib.wrapAndTagVarargsOrReturn(...))

    return self
end

---
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockResolvedValue(...)
    self._mockResolvedValue = varargsMatchingLib.wrapAndTagVarargsOrReturn(...)

    return self
end

---
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockResolvedValueOnce(...)
    table.insert(self._mockResolvedValueStack, varargsMatchingLib.wrapAndTagVarargsOrReturn(...))

    return self
end

---
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockRejectedValue(...)
    self._mockRejectedValue = varargsMatchingLib.wrapAndTagVarargsOrReturn(...)

    return self
end

---
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockRejectedValueOnce(...)
    table.insert(self._mockRejectedValueStack, ...)

    return self
end

---
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:withImplementation(fn, callback)
    self:mockImplementation(fn)
    callback()
    self:mockImplementation(nil)

    return self
end

function MOCK_FUNCTION_META:wasCalled()
    return self.callCount > 0
end

function MOCK_FUNCTION_META:wasCalledTimes(times)
    return self.callCount == times
end

function MOCK_FUNCTION_META:wasCalledWith(...)
    local args = varargsMatchingLib.wrapAndTagVarargsOrReturn(...)
    local calls = self.mock.calls

    for _, call in ipairs(calls) do
        if varargsMatchingLib.isWrappedVarargsEqual(args, call.args) then
            return true
        end
    end

    return false
end

function MOCK_FUNCTION_META:wasLastCalledWith(...)
    local args = varargsMatchingLib.wrapAndTagVarargsOrReturn(...)
    local lastCall = self.mock.lastCall

    if lastCall == nil then
        return false
    end

    return varargsMatchingLib.isWrappedVarargsEqual(args, lastCall.args)
end

function MOCK_FUNCTION_META:wasNthCalledWith(n, ...)
    local args = varargsMatchingLib.wrapAndTagVarargsOrReturn(...)
    local calls = self.mock.calls

    if calls[n] == nil then
        return false
    end

    return varargsMatchingLib.isWrappedVarargsEqual(args, calls[n].args)
end

function MOCK_FUNCTION_META:hasReturned()
    return #self.mock.results > 0
end

function MOCK_FUNCTION_META:hasReturnedTimes(times)
    return #self.mock.results == times
end

function MOCK_FUNCTION_META:hasReturnedWith(...)
    local args = varargsMatchingLib.wrapAndTagVarargsOrReturn(...)
    local results = self.mock.results

    for _, result in ipairs(results) do
        if varargsMatchingLib.isWrappedVarargsEqual(result.value, args) then
            return true
        end
    end

    return false
end

function MOCK_FUNCTION_META:hasLastReturnedWith(...)
    local args = varargsMatchingLib.wrapAndTagVarargsOrReturn(...)
    local lastResult = self.mock.results[#self.mock.results]

    if lastResult == nil then
        return false
    end

    return varargsMatchingLib.isWrappedVarargsEqual(lastResult.value, args)
end

function MOCK_FUNCTION_META:hasNthReturnedWith(n, ...)
    local args = varargsMatchingLib.wrapAndTagVarargsOrReturn(...)
    local nthResult = self.mock.results[n]

    if nthResult == nil then
        return false
    end

    return varargsMatchingLib.isWrappedVarargsEqual(nthResult.value, args)
end

function MOCK_FUNCTION_META:getCallArgs(n)
    local calls = self.mock.calls
    n = n or #calls

    if calls[n] == nil then
        return nil
    end

    return varargsMatchingLib.unwrapVarargsOrReturn(calls[n].args)
end

--- Internal function to get all call arguments.
--- Note: Because this is an internal function, it contains raw VarargsMatching objects where varargs were used to call.
--- @return table
function MOCK_FUNCTION_META:getAllCallArgs()
    local callArgs = {}

    for _, call in ipairs(self.mock.calls) do
        table.insert(callArgs, call.args)
    end

    return callArgs
end

--- Internal function to get all returned values.
--- Note: Because this is an internal function, it contains raw VarargsMatching objects where varargs were returned.
--- @return table
function MOCK_FUNCTION_META:getAllReturnValues()
    local returnValues = {}

    for i, result in ipairs(self.mock.results) do
        returnValues[i] = result.value
    end

    return returnValues
end

--- Internal function to get specific returned value.
--- Note: Because this is an internal function, it contains raw VarargsMatching objects where varargs were returned.
--- @return any
function MOCK_FUNCTION_META:getReturnedValue(n)
    local results = self.mock.results
    n = n or #results

    if results[n] == nil then
        return nil
    end

    return results[n].value
end

function MOCK_FUNCTION_META:getLastReturn()
    local lastResult = self.mock.results[#self.mock.results]

    if lastResult == nil then
        return nil
    end

    return varargsMatchingLib.unwrapVarargsOrReturn(lastResult.value)
end

--- Returns a new, unused mock function. Optionally takes a mock implementation.
--- @param defaultImplementation function
--- @return MockFunction
local function fn(defaultImplementation)
    defaultImplementation = defaultImplementation or function() end

    --- @type MockFunction
    local mockFn = setmetatable({}, MOCK_FUNCTION_META)
    mockFn:mockReset()
    mockFn:mockImplementation(defaultImplementation)

    return mockFn
end

local function makeMethodSpy(object, propertyName)
    local originalProperty = object[propertyName]
    local hadOwnProperty = rawget(object, propertyName) ~= nil
    local mockFn = fn(originalProperty)

    object[propertyName] = mockFn

    mockFn._restore = function()
        rawset(object, propertyName, hadOwnProperty and originalProperty or nil)
    end

    return mockFn
end

--- Add or extend the existing metatable of the object so that we can spy on a property.
--- @param object table
--- @param propertyName string
--- @param accessType string get or set
local function makePropertySpy(object, propertyName, accessType)
    local propertyValue = object[propertyName]
    local originalMetatable = getmetatable(object)
    local newMetaTable = {
        originalMetatable = originalMetatable
    }
    local mockFn = fn()

    object[propertyName] = nil -- Set it to nil, so that it is only accessible through the metatable

    setmetatable(object, newMetaTable)

    -- Other keys behave as they did before, through the original metatable if there was one
    local originalIndex = originalMetatable and originalMetatable.__index
    local originalNewIndex = originalMetatable and originalMetatable.__newindex

    newMetaTable.__index = function(self, key)
        if key == propertyName then
            if accessType == nil or accessType == "get" then
                mockFn()
            end

            return propertyValue
        end

        if type(originalIndex) == "function" then
            return originalIndex(self, key)
        elseif type(originalIndex) == "table" then
            return originalIndex[key]
        end
    end

    newMetaTable.__newindex = function(self, key, value)
        if key == propertyName then
            if accessType == nil or accessType == "set" then
                mockFn(value)
            end

            propertyValue = value
            return
        end

        if type(originalNewIndex) == "function" then
            originalNewIndex(self, key, value)
        elseif type(originalNewIndex) == "table" then
            originalNewIndex[key] = value
        else
            rawset(self, key, value)
        end
    end

    mockFn._restore = function()
        setmetatable(object, originalMetatable)
        rawset(object, propertyName, propertyValue)
    end

    return mockFn
end

local function spyOn(object, propertyName, accessType)
    local originalProperty = object[propertyName]
    local mock

    if type(originalProperty) == "function" then
        mock = makeMethodSpy(object, propertyName)
    else
        mock = makePropertySpy(object, propertyName, accessType)
    end

    allMocks[#allMocks + 1] = mock

    return mock
end

local function replaceProperty(object, propertyKey, value)
    local originalValue = object[propertyKey]
    object[propertyKey] = value

    allPropertyReplacements[#allPropertyReplacements + 1] = {
        object = object,
        propertyKey = propertyKey,
        originalValue = originalValue,
    }
end

local function isMockFunction(fn)
    return getmetatable(fn) == MOCK_FUNCTION_META
end

local function restoreAllMocks()
    for _, mockFn in ipairs(allMocks) do
        mockFn:mockRestore()
    end

    allMocks = {}

    for _, replacement in ipairs(allPropertyReplacements) do
        replacement.object[replacement.propertyKey] = replacement.originalValue
    end

    allPropertyReplacements = {}
end

return {
    MOCK_FUNCTION_META = MOCK_FUNCTION_META,
    fn = fn,
    spyOn = spyOn,
    isMockFunction = isMockFunction,
    restoreAllMocks = restoreAllMocks,
    replaceProperty = replaceProperty,
}

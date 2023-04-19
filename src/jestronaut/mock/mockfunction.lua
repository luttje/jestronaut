local asymmetricMatcherLib = require "jestronaut.expect.asymmetricmatchers.asymmetricmatcher"
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

  __call = function(self, ...)
    local args = {...}
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

    if #self._mockReturnValueStack > 0 then
      forcedReturn = self._mockReturnValueStack[#self._mockReturnValueStack]
      table.insert(self.mock.results, forcedReturn)
    end

    if #self._mockImplementationStack > 0 then
      local result = self._mockImplementationStack[#self._mockImplementationStack](...)
      table.insert(self.mock.results, result)
      table.remove(self._mockImplementationStack, #self._mockImplementationStack)
      return forcedReturn ~= nil and forcedReturn or result
    end

    if self._mockReturnThis then
      table.insert(self.mock.results, self)
      return forcedReturn ~= nil and forcedReturn or self
    end

    if self._mockReturnValue ~= nil then
      table.insert(self.mock.results, self._mockReturnValue)
      return forcedReturn ~= nil and forcedReturn or self._mockReturnValue
    end

    local result = self._mockImplementation(...)
    table.insert(self.mock.results, result)
    return forcedReturn ~= nil and forcedReturn or result
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
function MOCK_FUNCTION_META:mockReturnValue(value)
  self._mockReturnValue = value

  return self
end

--- 
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockReturnValueOnce(value)
  table.insert(self._mockReturnValueStack, value)

  return self
end

--- 
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockResolvedValue(value)
  self._mockResolvedValue = value

  return self
end

--- 
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockResolvedValueOnce(value)
  table.insert(self._mockResolvedValueStack, value)

  return self
end

--- 
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockRejectedValue(value)
  self._mockRejectedValue = value

  return self
end

--- 
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockRejectedValueOnce(value)
  table.insert(self._mockRejectedValueStack, value)

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
  local args = {...}
  local calls = self.mock.calls

  for _, call in ipairs(calls) do
    local callArgs = call.args
    local match = true

    for i, arg in ipairs(args) do
      if(asymmetricMatcherLib.isMatcher(arg))then
        if not asymmetricMatcherLib.matches(arg, callArgs[i]) then
          match = false
          break
        end
      else
        if arg ~= callArgs[i] then
          match = false
          break
        end
      end
    end

    if match then
      return true
    end
  end

  return false
end

function MOCK_FUNCTION_META:wasLastCalledWith(...)
  local args = {...}
  local lastCall = self.mock.lastCall

  if lastCall == nil then
    return false
  end

  local callArgs = lastCall.args
  local match = true

  for i, arg in ipairs(args) do
    if arg ~= callArgs[i] then
      match = false
      break
    end
  end

  return match
end

function MOCK_FUNCTION_META:wasNthCalledWith(n, ...)
  local args = {...}
  local calls = self.mock.calls

  if calls[n] == nil then
    return false
  end

  local callArgs = calls[n].args
  local match = true

  for i, arg in ipairs(args) do
    if arg ~= callArgs[i] then
      match = false
      break
    end
  end

  return match
end

function MOCK_FUNCTION_META:hasReturned()
  return #self.mock.results > 0
end

function MOCK_FUNCTION_META:hasReturnedTimes(times)
  return #self.mock.results == times
end

function MOCK_FUNCTION_META:hasReturnedWith(...)
  local args = {...}
  local results = self.mock.results

  for i, arg in ipairs(args) do
    if arg ~= results[i] then
      return false
    end
  end

  return true
end

function MOCK_FUNCTION_META:hasLastReturnedWith(value)
  local lastResult = self.mock.results[#self.mock.results]

  return lastResult == value
end

function MOCK_FUNCTION_META:hasNthReturnedWith(n, value)
  local results = self.mock.results

  return results[n] == value
end

function MOCK_FUNCTION_META:getCallArgs(n)
  local calls = self.mock.calls
  n = n or #calls

  if calls[n] == nil then
    return {}
  end

  return calls[n].args
end

function MOCK_FUNCTION_META:getLastReturn()
  return self.mock.results[#self.mock.results]
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
  local mockFn = fn(originalProperty)

  object[propertyName] = mockFn

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

  if newMetaTable.__index == nil then
    newMetaTable.__index = function(_, key)
      if key == propertyName then
        mockFn()
        return propertyValue
      end

      return rawget(object, key)
    end
  end

  if newMetaTable.__newindex == nil then
    newMetaTable.__newindex = function(_, key, value)
      if key == propertyName then
        mockFn(value)
        propertyValue = value
        return
      end

      rawset(object, key, value)
    end
  end

  if accessType ~= nil then
    if accessType == "get" then
      newMetaTable.__index = function(_, key)
        if key == propertyName then
          mockFn()
          return propertyValue
        end

        return rawget(object, key)
      end
    elseif accessType == "set" then
      newMetaTable.__newindex = function(_, key, value)
        if key == propertyName then
          mockFn(value)
          propertyValue = value
          return
        end

        rawset(object, key, value)
      end
    end
  end

  return mockFn
end

local function spyOn(object, propertyName, accessType)
  local originalProperty = object[propertyName]

  if originalProperty == nil then
    error("Cannot spyOn the method \"" .. propertyName .. "\" because it is nil")
  end

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

  for _, replacement in ipairs(allPropertyReplacements) do
    replacement.object[replacement.propertyKey] = replacement.originalValue
  end
end

return {
  MOCK_FUNCTION_META = MOCK_FUNCTION_META,
  fn = fn,
  spyOn = spyOn,
  isMockFunction = isMockFunction,
  restoreAllMocks = restoreAllMocks,
  replaceProperty = replaceProperty,
}
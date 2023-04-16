--- @class MockFunction
local MOCK_FUNCTION_META = {
  callCount = 0,
  nonMockedFunction = nil,
  mockName = nil,
  mock = {
    calls = {},
    results = {},
    instances = {},
    contexts = {},
    lastCall = nil,
  },
  mockImplementation = nil,
  mockImplementationStack = {},
  mockReturnThis = nil,
  mockReturnValue = nil,
  mockReturnValueStack = {},
  mockResolvedValue = nil,
  mockResolvedValueStack = {},
  mockRejectedValue = nil,
  mockRejectedValueStack = {},

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

    if #self.mockReturnValueStack > 0 then
      forcedReturn = self.mockReturnValueStack[#self.mockReturnValueStack]
      table.insert(self.mock.results, forcedReturn)
    end

    if #self.mockImplementationStack > 0 then
      local result = self.mockImplementationStack[#self.mockImplementationStack](...)
      table.insert(self.mock.results, result)
      table.remove(self.mockImplementationStack, #self.mockImplementationStack)
      return forcedReturn ~= nil and forcedReturn or result
    end

    if self.mockImplementation then
      local result = self:mockImplementation(...)
      table.insert(self.mock.results, result)
      return forcedReturn ~= nil and forcedReturn or result
    end

    if self.mockReturnThis then
      table.insert(self.mock.results, self)
      return forcedReturn ~= nil and forcedReturn or self
    end

    return self.nonMockedFunction(...)
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
  self.mockImplementation = nil
  self.mockImplementationStack = {}
  self.mockReturnThis = nil
  self.mockReturnValue = nil
  self.mockReturnValueStack = {}
  self.mockResolvedValue = nil
  self.mockResolvedValueStack = {}
  self.mockRejectedValue = nil
  self.mockRejectedValueStack = {}

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
  self.mockImplementation = fn

  return self
end

--- Accepts a function that will be used as an implementation of the mock for one call to the mocked function. Can be chained so that multiple function calls produce different results.
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockImplementationOnce(fn)
  table.insert(self.mockImplementationStack, fn)

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
  self.mockReturnThis = true

  return self
end

--- 
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockReturnValue(value)
  self.mockReturnValue = value

  return self
end

--- 
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockReturnValueOnce(value)
  table.insert(self.mockReturnValueStack, value)

  return self
end

--- 
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockResolvedValue(value)
  self.mockResolvedValue = value

  return self
end

--- 
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockResolvedValueOnce(value)
  table.insert(self.mockResolvedValueStack, value)

  return self
end

--- 
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockRejectedValue(value)
  self.mockRejectedValue = value

  return self
end

--- 
--- @param fn function
--- @return MockFunction
function MOCK_FUNCTION_META:mockRejectedValueOnce(value)
  table.insert(self.mockRejectedValueStack, value)

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

--- Returns a new, unused mock function. Optionally takes a mock implementation.
--- @param implementation function
--- @return MockFunction
local function fn(implementation)
  local mockFunction = {
    mockImplementation = implementation,
  }

  return setmetatable(mockFunction, MOCK_FUNCTION_META)
end


return {
  MOCK_FUNCTION_META = MOCK_FUNCTION_META,
  fn = fn,
}
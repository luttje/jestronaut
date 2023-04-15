local M = {}
M.mocks = {}

function M.fn(implementation)
  local mockFn = {}

  function mockFn.getMockImplementation()
    return mockFn._protoImpl
  end

  function mockFn.getMockName()
    return mockFn._name
  end

  function mockFn.mockClear()
    mockFn._isMockFunction = true
    mockFn._protoImpl = implementation
    mockFn._calls = {}
    mockFn._instances = {}
    mockFn._invocationCallOrder = {}
    mockFn._callResults = {}
    mockFn._call = {}
    mockFn._results = {}
    mockFn._resultsIndex = 0
    mockFn._isReturnValueLastSet = false
    mockFn._isResolvedValueLastSet = false
    mockFn._isRejectedValueLastSet = false
    mockFn._isReturnValueOnceLastSet = false
    mockFn._isResolvedValueOnceLastSet = false
    mockFn._isRejectedValueOnceLastSet = false
    mockFn._isImplementationLastSet = false
    mockFn._isImplementationOnceLastSet = false
    mockFn._isReturnThisLastSet = false
    mockFn._isReturnThisOnceLastSet = false
    mockFn._isThrowErrorLastSet = false
    mockFn._isThrowErrorOnceLastSet = false
  end
  mockFn.mockClear()

  function mockFn.mockReset()
    mockFn.mockClear()
    mockFn._protoImpl = nil
  end

  function mockFn.mockRestore()
    mockFn.mockReset()
    mockFn._isMockFunction = false
  end

  function mockFn.mockImplementation(fn)
    mockFn._isImplementationLastSet = true
    mockFn._protoImpl = fn
    return mockFn
  end

  function mockFn.mockImplementationOnce(fn)
    mockFn._isImplementationOnceLastSet = true
    mockFn._protoImpl = fn
    return mockFn
  end

  function mockFn.mockName(name)
    mockFn._name = name
    return mockFn
  end

  function mockFn.mockReturnValues(...)
    local values = {...}
    mockFn._isReturnValueLastSet = true
    mockFn._results[mockFn._resultsIndex] = values
    return mockFn
  end
  mockFn.returns = mockFn.mockReturnValues

  function mockFn.mockReturnValueOnce(value)
    mockFn._isReturnValueOnceLastSet = true
    mockFn._results[mockFn._resultsIndex] = value
    return mockFn
  end
  mockFn.returnOnce = mockFn.mockReturnValueOnce

  function mockFn.mockReturnValuesOnce(...)
    local values = {...}
    mockFn._isReturnValueOnceLastSet = true
    mockFn._results[mockFn._resultsIndex] = values
    return mockFn
  end
  mockFn.returnsOnce = mockFn.mockReturnValuesOnce

  function mockFn.mockThrowError(value)
    mockFn._isThrowErrorLastSet = true
    mockFn._results[mockFn._resultsIndex] = value
    return mockFn
  end

  function mockFn.mockThrowErrorOnce(value)
    mockFn._isThrowErrorOnceLastSet = true
    mockFn._results[mockFn._resultsIndex] = value
    return mockFn
  end

  function mockFn.mock(...)
    mockFn._isMockFunction = true
    mockFn._protoImpl = implementation
    mockFn._calls = {}
    mockFn._results = {}
    mockFn._instances = {}
    mockFn._invocationCallOrder = {}
    mockFn._callResults = {}
    mockFn._call = {}
    mockFn._results = {}
    mockFn._resultsIndex = 0
    mockFn._isReturnValueLastSet = false
    mockFn._isReturnValueOnceLastSet = false
    mockFn._isImplementationLastSet = false
    mockFn._isImplementationOnceLastSet = false
    mockFn._isReturnThisLastSet = false
    mockFn._isReturnThisOnceLastSet = false
    mockFn._isThrowErrorLastSet = false
    mockFn._isThrowErrorOnceLastSet = false
    return mockFn
  end

  return setmetatable(mockFn, {
    __call = function(self, ...)
      local args = {...}
      local call = {
        args = args,
        context = self,
        callId = #mockFn._calls + 1,
      }
      mockFn._calls[#mockFn._calls + 1] = call
      mockFn._invocationCallOrder[#mockFn._invocationCallOrder + 1] = call.callId
      mockFn._instances[#mockFn._instances + 1] = self
      mockFn._callResults[call.callId] = {}
      mockFn._call[call.callId] = call
      mockFn._resultsIndex = mockFn._resultsIndex + 1
      if mockFn._isImplementationLastSet then
        mockFn._isImplementationLastSet = false
        return mockFn._protoImpl(...)
      elseif mockFn._isImplementationOnceLastSet then
        mockFn._isImplementationOnceLastSet = false
        return mockFn._protoImpl(...)
      elseif mockFn._isReturnValueLastSet then
        mockFn._isReturnValueLastSet = false
        return mockFn._results[mockFn._resultsIndex]
      elseif mockFn._isReturnValueOnceLastSet then
        mockFn._isReturnValueOnceLastSet = false
        return mockFn._results[mockFn._resultsIndex]
      elseif mockFn._isReturnThisLastSet then
        mockFn._isReturnThisLastSet = false
        return self
      elseif mockFn._isReturnThisOnceLastSet then
        mockFn._isReturnThisOnceLastSet = false
        return self
      elseif mockFn._isThrowErrorLastSet then
        mockFn._isThrowErrorLastSet = false
        error(mockFn._results[mockFn._resultsIndex])
      elseif mockFn._isThrowErrorOnceLastSet then
        mockFn._isThrowErrorOnceLastSet = false
        error(mockFn._results[mockFn._resultsIndex])
      elseif mockFn._protoImpl then
        return mockFn._protoImpl(...)
      else
        return nil
      end
    end,
  })
end

return M
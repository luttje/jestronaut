local function toHaveBeenCalled(self)
  local mockFunction = self.value

  if not mockFunction then
    error('Expected a mock function, but received ' .. type(mockFunction))
  end

  local callCount = mockFunction.callCount

  return {
    pass = callCount > 0,
    message = function()
      if callCount == 0 then
        return 'Expected mock function to have been called, but it was not called.'
      end

      return 'Expected mock function not to have been called, but it was called ' .. callCount .. ' times.'
    end
  }
end

local function build(self)
  return function()
    return toHaveBeenCalled(self)
  end
end

return {
  toHaveBeenCalled = toHaveBeenCalled,
  build = build,
}
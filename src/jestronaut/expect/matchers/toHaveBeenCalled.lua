--- @param expect Expect
local function toHaveBeenCalled(expect)
  local mockFunction = expect.value

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

return {
  toHaveBeenCalled = toHaveBeenCalled,
}
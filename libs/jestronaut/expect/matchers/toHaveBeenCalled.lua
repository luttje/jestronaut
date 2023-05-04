--- @param expect Expect
local function toHaveBeenCalled(expect)
  local actual = expect.actual

  if not expect:checkEquals(true, actual:wasCalled()) then
    error("Expected " .. tostring(actual) .. (expect.inverse and " not" or "") ..  " to have been called")
  end

  return true
end

return {
  toHaveBeenCalled = toHaveBeenCalled,
  default = toHaveBeenCalled,
}